enum ChatRoomType {
  direct,
  group,
}

class ChatRoomModel {
  final String id;
  final String name;
  final String? photoUrl;
  final ChatRoomType type;
  final List<String> memberIds;
  final Map<String, String> memberNames;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final int unreadCount;
  final String? createdBy;
  final String? ownerId; // Chủ nhóm / Người giữ Key chính
  final List<String> deputyIds; // Danh sách Phó nhóm / Key phụ (tối đa 10 người)
  final bool onlyAdminsCanMessage; // Chỉ Trưởng/Phó nhóm mới được gửi tin nhắn
  final bool onlyAdminsCanAddMembers; // Chỉ Trưởng/Phó nhóm mới được thêm thành viên
  final List<String> deletedForUsers; // Danh sách người dùng đã xóa cuộc trò chuyện này khỏi danh sách
  final List<String> pinnedUsers; // Danh sách người dùng ghim cuộc trò chuyện này lên đầu
  final DateTime createdAt;
  final String? pinnedMessageId;
  final String? pinnedMessageText;
  final String? pinnedMessageSenderName;
  final String? bubbleThemeId;
  final String? wallpaperType;
  final String? wallpaperValue;

  ChatRoomModel({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.type,
    required this.memberIds,
    this.memberNames = const {},
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = 0,
    this.createdBy,
    this.ownerId,
    this.deputyIds = const [],
    this.onlyAdminsCanMessage = false,
    this.onlyAdminsCanAddMembers = false,
    this.deletedForUsers = const [],
    this.pinnedUsers = const [],
    required this.createdAt,
    this.pinnedMessageId,
    this.pinnedMessageText,
    this.pinnedMessageSenderName,
    this.bubbleThemeId,
    this.wallpaperType,
    this.wallpaperValue,
  });

  String get effectiveOwnerId => (ownerId != null && ownerId!.isNotEmpty) ? ownerId! : (createdBy ?? '');
  bool isOwner(String userId) => effectiveOwnerId == userId;
  bool isDeputy(String userId) => deputyIds.contains(userId);
  bool isAdmin(String userId) => isOwner(userId) || isDeputy(userId);
  bool canSendMessage(String userId) => type != ChatRoomType.group || !onlyAdminsCanMessage || isAdmin(userId);
  bool isPinnedFor(String userId) => pinnedUsers.contains(userId);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'type': type.name,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'createdBy': createdBy,
      'ownerId': effectiveOwnerId,
      'deputyIds': deputyIds,
      'onlyAdminsCanMessage': onlyAdminsCanMessage,
      'onlyAdminsCanAddMembers': onlyAdminsCanAddMembers,
      'deletedForUsers': deletedForUsers,
      'pinnedUsers': pinnedUsers,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'pinnedMessageId': pinnedMessageId,
      'pinnedMessageText': pinnedMessageText,
      'pinnedMessageSenderName': pinnedMessageSenderName,
      'bubbleThemeId': bubbleThemeId,
      'wallpaperType': wallpaperType,
      'wallpaperValue': wallpaperValue,
    };
  }

  String getDisplayName(String currentUserId) {
    if (type == ChatRoomType.direct) {
      final otherUid = memberIds.firstWhere((id) => id != currentUserId, orElse: () => '');
      if (otherUid.isNotEmpty && memberNames.containsKey(otherUid)) {
        return memberNames[otherUid]!;
      }
    }
    return name;
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val);
      try {
        return (val as dynamic).toDate() as DateTime?;
      } catch (_) {}
      return null;
    }

    final rawCreatedBy = map['createdBy'] as String?;
    final rawOwnerId = map['ownerId'] as String?;

    return ChatRoomModel(
      id: id,
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      type: map['type'] == 'group' ? ChatRoomType.group : ChatRoomType.direct,
      memberIds: List<String>.from(map['memberIds'] ?? []),
      memberNames: Map<String, String>.from(map['memberNames'] ?? {}),
      lastMessage: map['lastMessage'],
      lastMessageTime: parseDate(map['lastMessageTime']),
      lastMessageSenderId: map['lastMessageSenderId'],
      unreadCount: map['unreadCount'] ?? 0,
      createdBy: rawCreatedBy,
      ownerId: (rawOwnerId != null && rawOwnerId.isNotEmpty) ? rawOwnerId : rawCreatedBy,
      deputyIds: List<String>.from(map['deputyIds'] ?? []),
      onlyAdminsCanMessage: map['onlyAdminsCanMessage'] ?? false,
      onlyAdminsCanAddMembers: map['onlyAdminsCanAddMembers'] ?? false,
      deletedForUsers: List<String>.from(map['deletedForUsers'] ?? []),
      pinnedUsers: List<String>.from(map['pinnedUsers'] ?? []),
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      pinnedMessageId: map['pinnedMessageId'],
      pinnedMessageText: map['pinnedMessageText'],
      pinnedMessageSenderName: map['pinnedMessageSenderName'],
      bubbleThemeId: map['bubbleThemeId'],
      wallpaperType: map['wallpaperType'],
      wallpaperValue: map['wallpaperValue'],
    );
  }
}
