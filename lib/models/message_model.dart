enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  location,
  call,
}

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy;
  final bool isRecalled;
  final bool isDeleted;

  // Media & Location specific fields
  final String? mediaUrl;
  final List<String> mediaUrls; // Hỗ trợ gửi nhiều ảnh & video (tối đa 10)
  final List<String> mediaTypes; // 'image' hoặc 'video' tương ứng
  final String? fileName;
  final int? fileSize;
  final int? audioDurationSec;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;

  // Zalo-like features: Reactions & Reply
  final Map<String, String> reactions; // userId -> emoji ('❤️', '👍', '😂', '😮', '😢', '😡')
  final String? replyToMessageId;
  final String? replyToContent;
  final String? replyToSenderName;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.readBy = const [],
    this.isRecalled = false,
    this.isDeleted = false,
    this.mediaUrl,
    this.mediaUrls = const [],
    this.mediaTypes = const [],
    this.fileName,
    this.fileSize,
    this.audioDurationSec,
    this.latitude,
    this.longitude,
    this.locationAddress,
    this.reactions = const {},
    this.replyToMessageId,
    this.replyToContent,
    this.replyToSenderName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'readBy': readBy,
      'isRecalled': isRecalled,
      'isDeleted': isDeleted,
      'mediaUrl': mediaUrl,
      'mediaUrls': mediaUrls,
      'mediaTypes': mediaTypes,
      'fileName': fileName,
      'fileSize': fileSize,
      'audioDurationSec': audioDurationSec,
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
      'reactions': reactions,
      'replyToMessageId': replyToMessageId,
      'replyToContent': replyToContent,
      'replyToSenderName': replyToSenderName,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    final rawUrls = List<String>.from(map['mediaUrls'] ?? []);
    final singleUrl = map['mediaUrl'] as String?;
    final resolvedUrls = rawUrls.isNotEmpty ? rawUrls : (singleUrl != null && singleUrl.isNotEmpty ? [singleUrl] : <String>[]);

    final rawTypes = List<String>.from(map['mediaTypes'] ?? []);
    final resolvedTypes = rawTypes.isNotEmpty
        ? rawTypes
        : List<String>.filled(resolvedUrls.length, map['type'] == 'video' ? 'video' : 'image');

    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderAvatar: map['senderAvatar'],
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      readBy: List<String>.from(map['readBy'] ?? []),
      isRecalled: map['isRecalled'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      mediaUrl: singleUrl ?? (resolvedUrls.isNotEmpty ? resolvedUrls.first : null),
      mediaUrls: resolvedUrls,
      mediaTypes: resolvedTypes,
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      audioDurationSec: map['audioDurationSec'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationAddress: map['locationAddress'],
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
      replyToMessageId: map['replyToMessageId'],
      replyToContent: map['replyToContent'],
      replyToSenderName: map['replyToSenderName'],
    );
  }
}
