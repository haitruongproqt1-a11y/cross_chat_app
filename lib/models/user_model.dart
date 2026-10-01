class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String statusMessage;
  final bool isOnline;
  final DateTime lastSeen;
  final String? fcmToken;

  // Trường thông tin bổ sung cho tính năng Tìm bạn quanh đây
  final String gender; // 'Nam', 'Nữ', 'Khác'
  final int? birthYear;
  final String hometown;
  final double? latitude;
  final double? longitude;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    this.statusMessage = 'Xin chào! Tôi đang dùng KINI CHAT.',
    this.isOnline = false,
    required this.lastSeen,
    this.fcmToken,
    this.gender = 'Chưa xác định',
    this.birthYear,
    this.hometown = '',
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'statusMessage': statusMessage,
      'isOnline': isOnline,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'fcmToken': fcmToken,
      'gender': gender,
      'birthYear': birthYear,
      'hometown': hometown,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'Người dùng',
      photoUrl: map['photoUrl'] ?? '',
      statusMessage: map['statusMessage'] ?? 'Xin chào! Tôi đang dùng KINI CHAT.',
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'])
          : DateTime.now(),
      fcmToken: map['fcmToken'],
      gender: map['gender'] ?? 'Chưa xác định',
      birthYear: map['birthYear'],
      hometown: map['hometown'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? statusMessage,
    bool? isOnline,
    DateTime? lastSeen,
    String? fcmToken,
    String? gender,
    int? birthYear,
    String? hometown,
    double? latitude,
    double? longitude,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      statusMessage: statusMessage ?? this.statusMessage,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
      gender: gender ?? this.gender,
      birthYear: birthYear ?? this.birthYear,
      hometown: hometown ?? this.hometown,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
