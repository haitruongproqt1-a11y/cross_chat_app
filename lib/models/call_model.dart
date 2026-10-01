enum CallType {
  audio,
  video,
}

enum CallStatus {
  ringing,
  connected,
  ended,
  rejected,
  missed,
}

class CallSessionModel {
  final String callId;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String receiverId;
  final String receiverName;
  final CallType type;
  final CallStatus status;
  final DateTime createdAt;
  final Map<String, dynamic>? sdpOffer;
  final Map<String, dynamic>? sdpAnswer;

  CallSessionModel({
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.receiverId,
    required this.receiverName,
    required this.type,
    this.status = CallStatus.ringing,
    required this.createdAt,
    this.sdpOffer,
    this.sdpAnswer,
  });

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'type': type.name,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'sdpOffer': sdpOffer,
      'sdpAnswer': sdpAnswer,
    };
  }

  factory CallSessionModel.fromMap(Map<String, dynamic> map, String id) {
    return CallSessionModel(
      callId: id,
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerAvatar: map['callerAvatar'],
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      type: map['type'] == 'video' ? CallType.video : CallType.audio,
      status: CallStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CallStatus.ringing,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      sdpOffer: map['sdpOffer'],
      sdpAnswer: map['sdpAnswer'],
    );
  }
}
