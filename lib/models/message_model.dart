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
  final String? fileName;
  final int? fileSize;
  final int? audioDurationSec;
  final double? latitude;
  final double? longitude;
  final String? locationAddress;

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
    this.fileName,
    this.fileSize,
    this.audioDurationSec,
    this.latitude,
    this.longitude,
    this.locationAddress,
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
      'fileName': fileName,
      'fileSize': fileSize,
      'audioDurationSec': audioDurationSec,
      'latitude': latitude,
      'longitude': longitude,
      'locationAddress': locationAddress,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
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
      mediaUrl: map['mediaUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      audioDurationSec: map['audioDurationSec'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationAddress: map['locationAddress'],
    );
  }
}
