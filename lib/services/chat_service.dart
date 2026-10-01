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

  // Stream of chat rooms for current user
  Stream<List<ChatRoomModel>> getChatRooms(String currentUserId) {
    return _firestore
        .collection('chat_rooms')
        .where('memberIds', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatRoomModel.fromMap(doc.data(), doc.id)).toList();
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
      return snapshot.docs.map((doc) {
        final msg = MessageModel.fromMap(doc.data(), doc.id);
        // Decrypt if it's text message
        if (msg.type == MessageType.text) {
          return MessageModel(
            id: msg.id,
            senderId: msg.senderId,
            senderName: msg.senderName,
            senderAvatar: msg.senderAvatar,
            content: _security.decryptText(msg.content),
            type: msg.type,
            timestamp: msg.timestamp,
            isRead: msg.isRead,
            readBy: msg.readBy,
            mediaUrl: msg.mediaUrl,
            fileName: msg.fileName,
            fileSize: msg.fileSize,
            audioDurationSec: msg.audioDurationSec,
            latitude: msg.latitude,
            longitude: msg.longitude,
            locationAddress: msg.locationAddress,
          );
        }
        return msg;
      }).toList();
    });
  }

  // Create or retrieve existing direct 1-1 chat room
  Future<String> getOrCreateDirectRoom({
    required UserModel currentUser,
    required UserModel otherUser,
  }) async {
    // Deterministic direct room id or query
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

    // Otherwise create new direct room
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
    );

    await newRoomRef.set(newRoom.toMap());
    return newRoomRef.id;
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
      lastMessage: '${creator.displayName} created the group',
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
    String? fileName,
    int? fileSize,
    int? audioDurationSec,
    double? latitude,
    double? longitude,
    String? locationAddress,
  }) async {
    final msgRef = _firestore.collection('chat_rooms').doc(roomId).collection('messages').doc();

    // Encrypt text content
    final secureContent = type == MessageType.text ? _security.encryptText(content) : content;

    final message = MessageModel(
      id: msgRef.id,
      senderId: sender.uid,
      senderName: sender.displayName,
      senderAvatar: sender.photoUrl,
      content: secureContent,
      type: type,
      timestamp: DateTime.now(),
      readBy: [sender.uid],
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
      audioDurationSec: audioDurationSec,
      latitude: latitude,
      longitude: longitude,
      locationAddress: locationAddress,
    );

    await msgRef.set(message.toMap());

    // Update Room's last message
    String previewText = content;
    if (type == MessageType.image) previewText = '📷 [Image]';
    if (type == MessageType.video) previewText = '🎥 [Video]';
    if (type == MessageType.audio) previewText = '🎤 [Voice message]';
    if (type == MessageType.file) previewText = '📎 $fileName';
    if (type == MessageType.location) previewText = '📍 [Location shared]';

    await _firestore.collection('chat_rooms').doc(roomId).update({
      'lastMessage': previewText,
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      'lastMessageSenderId': sender.uid,
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

  // Get all registered users (Contacts)
  Stream<List<UserModel>> getAllUsers(String currentUserId) {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Cập nhật vị trí GPS của người dùng lên Firestore
  Future<void> updateUserLocation(String uid, double latitude, double longitude) async {
    await _firestore.collection('users').doc(uid).update({
      'latitude': latitude,
      'longitude': longitude,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    });
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
