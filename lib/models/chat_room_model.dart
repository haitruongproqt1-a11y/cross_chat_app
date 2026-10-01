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
  final DateTime createdAt;

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
    required this.createdAt,
  });

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
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoomModel(
      id: id,
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      type: map['type'] == 'group' ? ChatRoomType.group : ChatRoomType.direct,
      memberIds: List<String>.from(map['memberIds'] ?? []),
      memberNames: Map<String, String>.from(map['memberNames'] ?? {}),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
      unreadCount: map['unreadCount'] ?? 0,
      createdBy: map['createdBy'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }
}
