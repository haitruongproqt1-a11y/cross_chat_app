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
      createdBy: map['createdBy'],
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }
}
