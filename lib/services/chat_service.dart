import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'security_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SecurityService _security = SecurityService();

  // Stream of chat rooms for current user (sắp xếp client-side không cần composite index)
  Stream<List<ChatRoomModel>> getChatRooms(String currentUserId) {
    return _firestore
        .collection('chat_rooms')
        .where('memberIds', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => ChatRoomModel.fromMap(doc.data(), doc.id)).toList();
      
      // Khử trùng lặp phòng chat 1-1 (Deduplicate direct rooms)
      final Map<String, ChatRoomModel> uniqueRooms = {};
      for (var room in list) {
        if (room.type == ChatRoomType.direct) {
          final otherUser = room.memberIds.firstWhere((id) => id != currentUserId, orElse: () => '');
          final key = 'direct_$otherUser';
          if (!uniqueRooms.containsKey(key)) {
            uniqueRooms[key] = room;
          } else {
            final existing = uniqueRooms[key]!;
            final timeExisting = existing.lastMessageTime ?? existing.createdAt;
            final timeCurrent = room.lastMessageTime ?? room.createdAt;
            if (timeCurrent.isAfter(timeExisting)) {
              uniqueRooms[key] = room;
            }
          }
        } else {
          uniqueRooms[room.id] = room;
        }
      }

      final result = uniqueRooms.values.toList();
      result.sort((a, b) {
        final timeA = a.lastMessageTime ?? a.createdAt;
        final timeB = b.lastMessageTime ?? b.createdAt;
        return timeB.compareTo(timeA);
      });
      return result;
    });
  }

  // Stream of messages in a room
  Stream<List<MessageModel>> getMessages(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final msg = MessageModel.fromMap(doc.data(), doc.id);
            if (msg.isDeleted) return null;

            String decryptedContent = msg.content;
            if (msg.type == MessageType.text && msg.content.startsWith('ENC:')) {
              decryptedContent = _security.decryptForRoom(msg.content, roomId);
              if (decryptedContent.startsWith('ENC:')) {
                decryptedContent = decryptedContent.replaceFirst('ENC:', '');
              }
            }

            return MessageModel(
              id: msg.id,
              senderId: msg.senderId,
              senderName: msg.senderName,
              senderAvatar: msg.senderAvatar,
              content: msg.isRecalled ? 'Tin nhắn đã được thu hồi' : decryptedContent,
              type: msg.type,
              timestamp: msg.timestamp,
              isRead: msg.isRead,
              readBy: msg.readBy,
              isRecalled: msg.isRecalled,
              isDeleted: msg.isDeleted,
              mediaUrl: msg.mediaUrl,
              fileName: msg.fileName,
              fileSize: msg.fileSize,
              audioDurationSec: msg.audioDurationSec,
              latitude: msg.latitude,
              longitude: msg.longitude,
              locationAddress: msg.locationAddress,
              reactions: msg.reactions,
              replyToMessageId: msg.replyToMessageId,
              replyToContent: msg.replyToContent,
              replyToSenderName: msg.replyToSenderName,
            );
          })
          .whereType<MessageModel>()
          .toList();
    });
  }

  // Create or retrieve existing direct 1-1 chat room
  Future<String> getOrCreateDirectRoom({
    required UserModel currentUser,
    required UserModel otherUser,
  }) async {
    final query = await _firestore
        .collection('chat_rooms')
        .where('type', isEqualTo: 'direct')
        .where('memberIds', arrayContains: currentUser.uid)
        .get();

    for (var doc in query.docs) {
      final members = List<String>.from(doc['memberIds'] ?? []);
      if (members.contains(otherUser.uid)) {
        return doc.id;
      }
    }

    final newRoomRef = _firestore.collection('chat_rooms').doc();
    final newRoom = ChatRoomModel(
      id: newRoomRef.id,
      name: otherUser.displayName,
      photoUrl: otherUser.photoUrl,
      type: ChatRoomType.direct,
      memberIds: [currentUser.uid, otherUser.uid],
      memberNames: {
        currentUser.uid: currentUser.displayName,
        otherUser.uid: otherUser.displayName,
      },
      createdAt: DateTime.now(),
      lastMessage: 'Bắt đầu cuộc trò chuyện mới',
      lastMessageTime: DateTime.now(),
      lastMessageSenderId: currentUser.uid,
    );

    await newRoomRef.set(newRoom.toMap());
    return newRoomRef.id;
  }

  // Thêm bạn bè
  Future<void> addFriend({required String currentUserId, required String friendUserId}) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'friends': FieldValue.arrayUnion([friendUserId]),
    });
    await _firestore.collection('users').doc(friendUserId).update({
      'friends': FieldValue.arrayUnion([currentUserId]),
    });
  }

  // Xóa bạn bè
  Future<void> removeFriend({required String currentUserId, required String friendUserId}) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'friends': FieldValue.arrayRemove([friendUserId]),
    });
    await _firestore.collection('users').doc(friendUserId).update({
      'friends': FieldValue.arrayRemove([currentUserId]),
    });
  }

  // Chặn người dùng (tin nhắn & cuộc gọi)
  Future<void> blockUser({required String currentUserId, required String targetUserId}) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayUnion([targetUserId]),
    });
  }

  // Bỏ chặn người dùng
  Future<void> unblockUser({required String currentUserId, required String targetUserId}) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayRemove([targetUserId]),
    });
  }

  // Cập nhật quyền riêng tư tìm kiếm
  Future<void> updateSearchPrivacy({
    required String currentUserId,
    bool? allowSearchByName,
    bool? allowSearchByEmail,
    bool? allowSearchById,
  }) async {
    final Map<String, dynamic> updates = {};
    if (allowSearchByName != null) updates['allowSearchByName'] = allowSearchByName;
    if (allowSearchByEmail != null) updates['allowSearchByEmail'] = allowSearchByEmail;
    if (allowSearchById != null) updates['allowSearchById'] = allowSearchById;
    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(currentUserId).update(updates);
    }
  }

  // Create a new Group Chat
  Future<String> createGroupChat({
    required String groupName,
    String? groupAvatar,
    required UserModel creator,
    required List<UserModel> selectedMembers,
  }) async {
    final roomRef = _firestore.collection('chat_rooms').doc();
    final allMembers = [creator, ...selectedMembers];
    final memberIds = allMembers.map((u) => u.uid).toList();
    final memberNames = {for (var u in allMembers) u.uid: u.displayName};

    final groupRoom = ChatRoomModel(
      id: roomRef.id,
      name: groupName,
      photoUrl: groupAvatar ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(groupName)}&background=0D8ABC&color=fff',
      type: ChatRoomType.group,
      memberIds: memberIds,
      memberNames: memberNames,
      createdBy: creator.uid,
      createdAt: DateTime.now(),
      lastMessage: '${creator.displayName} đã tạo nhóm',
      lastMessageTime: DateTime.now(),
      lastMessageSenderId: creator.uid,
    );

    await roomRef.set(groupRoom.toMap());
    return roomRef.id;
  }

  // Send a message
  Future<void> sendMessage({
    required String roomId,
    required UserModel sender,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
    List<String> mediaUrls = const [],
    List<String> mediaTypes = const [],
    String? fileName,
    int? fileSize,
    int? audioDurationSec,
    double? latitude,
    double? longitude,
    String? locationAddress,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderName,
  }) async {
    final msgRef = _firestore.collection('chat_rooms').doc(roomId).collection('messages').doc();

    final secureContent = content;

    final message = MessageModel(
      id: msgRef.id,
      senderId: sender.uid,
      senderName: sender.displayName,
      senderAvatar: sender.photoUrl,
      content: secureContent,
      type: type,
      timestamp: DateTime.now(),
      readBy: [sender.uid],
      mediaUrl: mediaUrl ?? (mediaUrls.isNotEmpty ? mediaUrls.first : null),
      mediaUrls: mediaUrls,
      mediaTypes: mediaTypes,
      fileName: fileName,
      fileSize: fileSize,
      audioDurationSec: audioDurationSec,
      latitude: latitude,
      longitude: longitude,
      locationAddress: locationAddress,
      replyToMessageId: replyToMessageId,
      replyToContent: replyToContent,
      replyToSenderName: replyToSenderName,
    );

    await msgRef.set(message.toMap());

    // Update Room's last message
    String previewText = content;
    if (mediaUrls.length > 1) {
      previewText = '📷 [${mediaUrls.length} ảnh/video]';
    } else if (type == MessageType.image) {
      previewText = '📷 [Hình ảnh]';
    } else if (type == MessageType.video) {
      previewText = '🎥 [Video]';
    } else if (type == MessageType.audio) {
      previewText = '🎤 [Tin nhắn thoại]';
    } else if (type == MessageType.file) {
      previewText = '📎 $fileName';
    } else if (type == MessageType.location) {
      previewText = '📍 [Vị trí ghim]';
    }

    await _firestore.collection('chat_rooms').doc(roomId).update({
      'lastMessage': previewText,
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      'lastMessageSenderId': sender.uid,
      'lastMessageSenderName': sender.displayName,
    });
  }

  // Thả / Thay đổi biểu cảm vào tin nhắn
  Future<void> addMessageReaction({
    required String roomId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.$userId': emoji,
    });
  }

  // Gỡ biểu cảm khỏi tin nhắn
  Future<void> removeMessageReaction({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.$userId': FieldValue.delete(),
    });
  }

  // Ghim tin nhắn trong phòng chat
  Future<void> pinMessage({
    required String roomId,
    required String messageId,
    required String text,
    required String senderName,
  }) async {
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'pinnedMessageId': messageId,
      'pinnedMessageText': text,
      'pinnedMessageSenderName': senderName,
    });
  }

  // Gỡ ghim tin nhắn
  Future<void> unpinMessage(String roomId) async {
    await _firestore.collection('chat_rooms').doc(roomId).update({
      'pinnedMessageId': FieldValue.delete(),
      'pinnedMessageText': FieldValue.delete(),
      'pinnedMessageSenderName': FieldValue.delete(),
    });
  }

  // Thu hồi tin nhắn (Recall)
  Future<void> recallMessage(String roomId, String messageId) async {
    await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId)
        .update({
      'isRecalled': true,
      'content': 'Tin nhắn đã được thu hồi',
    });
  }

  // Xóa tin nhắn (Delete for me/hide)
  Future<void> deleteMessage(String roomId, String messageId) async {
    await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId)
        .update({
      'isDeleted': true,
    });
  }

  // Mark message as read
  Future<void> markAsRead(String roomId, String messageId, String userId) async {
    await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId)
        .update({
      'readBy': FieldValue.arrayUnion([userId]),
      'isRead': true,
    });
  }

  // Clear chat history / delete room
  Future<void> deleteRoom(String roomId) async {
    final messages = await _firestore.collection('chat_rooms').doc(roomId).collection('messages').get();
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }
    await _firestore.collection('chat_rooms').doc(roomId).delete();
  }

  // Lấy danh sách BẠN BÈ thực tế (Chỉ người đã kết bạn)
  Stream<List<UserModel>> getFriendsStream(String currentUserId) {
    return _firestore.collection('users').doc(currentUserId).snapshots().asyncMap((userDoc) async {
      if (!userDoc.exists || userDoc.data() == null) return <UserModel>[];
      final friendIds = List<String>.from(userDoc.data()!['friends'] ?? []);
      if (friendIds.isEmpty) return <UserModel>[];

      final List<UserModel> friends = [];
      for (var i = 0; i < friendIds.length; i += 30) {
        final chunk = friendIds.sublist(i, (i + 30 > friendIds.length) ? friendIds.length : i + 30);
        final snapshot = await _firestore.collection('users').where(FieldPath.documentId, whereIn: chunk).get();
        for (var doc in snapshot.docs) {
          friends.add(UserModel.fromMap(doc.data(), doc.id));
        }
      }
      return friends;
    });
  }

  // Get all registered users (dùng cho tìm kiếm hoặc gợi ý)
  Stream<List<UserModel>> getAllUsers(String currentUserId) {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Tìm kiếm bạn bè chính xác theo Gmail, Tên, hoặc ID cá nhân
  Future<List<UserModel>> searchUsers({
    required String currentUserId,
    required String query,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final snapshot = await _firestore.collection('users').get();
    final results = <UserModel>[];

    for (var doc in snapshot.docs) {
      if (doc.id == currentUserId) continue;
      final data = doc.data();
      final user = UserModel.fromMap(data, doc.id);

      final matchEmail = user.email.toLowerCase().contains(q);
      final matchName = user.displayName.toLowerCase().contains(q);
      final matchId = user.uid.toLowerCase().contains(q);

      if (matchEmail || matchName || matchId) {
        results.add(user);
      }
    }
    return results;
  }

  // Lấy thông tin người dùng theo UID (cho tính năng quét QR / ID)
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  // Cập nhật vị trí GPS của người dùng lên Firestore
  Future<void> updateUserLocation(String uid, double latitude, double longitude) async {
    await _firestore.collection('users').doc(uid).update({
      'latitude': latitude,
      'longitude': longitude,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Lưu lịch sử cuộc gọi vào đoạn chat
  Future<void> sendCallLogMessage({
    required String roomId,
    required String callerId,
    required String callerName,
    required bool isVideo,
    required bool isConnected,
    required int durationSeconds,
  }) async {
    try {
      final msgRef = _firestore.collection('chat_rooms').doc(roomId).collection('messages').doc();

      String content;
      if (isConnected) {
        final m = durationSeconds ~/ 60;
        final s = durationSeconds % 60;
        final timeStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        content = isVideo ? 'Cuộc gọi video ($timeStr)' : 'Cuộc gọi thoại ($timeStr)';
      } else {
        content = isVideo ? 'Cuộc gọi video nhỡ' : 'Cuộc gọi thoại nhỡ';
      }

      final message = MessageModel(
        id: msgRef.id,
        senderId: callerId,
        senderName: callerName,
        content: content,
        type: MessageType.call,
        timestamp: DateTime.now(),
        audioDurationSec: durationSeconds,
      );

      await msgRef.set(message.toMap());
      // Lưu vào lịch sử cuộc trò chuyện giữa 2 người, không ghi đè lastMessage ngoài mục trò chuyện
    } catch (e) {
      // Bỏ qua lỗi nếu không thể ghi nhật ký
    }
  }

  // Cập nhật giao diện phòng trò chuyện (kiểu bong bóng & hình nền)
  Future<void> updateRoomTheme({
    required String roomId,
    String? bubbleThemeId,
    String? wallpaperType,
    String? wallpaperValue,
  }) async {
    final Map<String, dynamic> updateData = {};
    if (bubbleThemeId != null) updateData['bubbleThemeId'] = bubbleThemeId;
    if (wallpaperType != null) updateData['wallpaperType'] = wallpaperType;
    if (wallpaperValue != null) updateData['wallpaperValue'] = wallpaperValue;
    if (updateData.isNotEmpty) {
      await _firestore.collection('chat_rooms').doc(roomId).update(updateData);
    }
  }

  // Tính khoảng cách giữa 2 tọa độ GPS (Công thức Haversine - đơn vị km)
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}
