class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String statusMessage;
  final bool isOnline;
  final DateTime lastSeen;
  final String? fcmToken;

  // Tên đăng nhập và bảo mật khôi phục mật khẩu
  final String username;
  final String securityQuestion;
  final String securityAnswerHash;

  // Trường thông tin bổ sung cho tính năng Tìm bạn quanh đây
  final String gender; // 'Nam', 'Nữ', 'Khác'
  final int? birthYear;
  final String hometown;
  final String maritalStatus; // 'Độc thân', 'Đã kết hôn', 'Đang tìm hiểu', 'Hẹn hò'
  final String bio; // Giới thiệu bản thân
  final String job; // Nghề nghiệp / công việc
  final bool shareLocation; // Chỉ người bật chia sẻ mới tìm được và xuất hiện quanh đây
  final double? latitude;
  final double? longitude;

  final List<String> friends;
  final List<String> blockedUsers;
  final bool allowSearchByName;
  final bool allowSearchByEmail;
  final bool allowSearchById;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    this.statusMessage = 'Xin chào! Tôi đang dùng KINI CHAT.',
    this.isOnline = false,
    required this.lastSeen,
    this.fcmToken,
    this.username = '',
    this.securityQuestion = 'Tên trường tiểu học đầu tiên của bạn là gì?',
    this.securityAnswerHash = '',
    this.gender = 'Chưa xác định',
    this.birthYear,
    this.hometown = '',
    this.maritalStatus = 'Độc thân',
    this.bio = '',
    this.job = '',
    this.shareLocation = false,
    this.latitude,
    this.longitude,
    this.friends = const [],
    this.blockedUsers = const [],
    this.allowSearchByName = true,
    this.allowSearchByEmail = true,
    this.allowSearchById = true,
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
      'username': username,
      'securityQuestion': securityQuestion,
      'securityAnswerHash': securityAnswerHash,
      'gender': gender,
      'birthYear': birthYear,
      'hometown': hometown,
      'maritalStatus': maritalStatus,
      'bio': bio,
      'job': job,
      'shareLocation': shareLocation,
      'latitude': latitude,
      'longitude': longitude,
      'friends': friends,
      'blockedUsers': blockedUsers,
      'allowSearchByName': allowSearchByName,
      'allowSearchByEmail': allowSearchByEmail,
      'allowSearchById': allowSearchById,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    final rawEmail = map['email'] ?? '';
    final defaultUsername = map['username'] ?? (rawEmail.isNotEmpty ? rawEmail.toString().split('@').first : id.substring(0, 6));

    return UserModel(
      uid: id,
      email: rawEmail,
      displayName: map['displayName'] ?? 'Người dùng',
      photoUrl: map['photoUrl'] ?? '',
      statusMessage: map['statusMessage'] ?? 'Xin chào! Tôi đang dùng KINI CHAT.',
      isOnline: map['isOnline'] ?? false,
      lastSeen: () {
        final ls = map['lastSeen'];
        if (ls == null) return DateTime.now();
        if (ls is int) return DateTime.fromMillisecondsSinceEpoch(ls);
        if (ls is String) return DateTime.tryParse(ls) ?? DateTime.now();
        try {
          return (ls as dynamic).toDate() as DateTime;
        } catch (_) {
          return DateTime.now();
        }
      }(),
      fcmToken: map['fcmToken'],
      username: defaultUsername,
      securityQuestion: map['securityQuestion'] ?? 'Tên trường tiểu học đầu tiên của bạn là gì?',
      securityAnswerHash: map['securityAnswerHash'] ?? '',
      gender: map['gender'] ?? 'Chưa xác định',
      birthYear: map['birthYear'],
      hometown: map['hometown'] ?? '',
      maritalStatus: map['maritalStatus'] ?? 'Độc thân',
      bio: map['bio'] ?? '',
      job: map['job'] ?? '',
      shareLocation: map['shareLocation'] ?? false,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      friends: List<String>.from(map['friends'] ?? []),
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
      allowSearchByName: map['allowSearchByName'] ?? true,
      allowSearchByEmail: map['allowSearchByEmail'] ?? true,
      allowSearchById: map['allowSearchById'] ?? true,
    );
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? statusMessage,
    bool? isOnline,
    DateTime? lastSeen,
    String? fcmToken,
    String? username,
    String? securityQuestion,
    String? securityAnswerHash,
    String? gender,
    int? birthYear,
    String? hometown,
    String? maritalStatus,
    String? bio,
    String? job,
    bool? shareLocation,
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
      username: username ?? this.username,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswerHash: securityAnswerHash ?? this.securityAnswerHash,
      gender: gender ?? this.gender,
      birthYear: birthYear ?? this.birthYear,
      hometown: hometown ?? this.hometown,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      bio: bio ?? this.bio,
      job: job ?? this.job,
      shareLocation: shareLocation ?? this.shareLocation,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      friends: friends,
      blockedUsers: blockedUsers,
      allowSearchByName: allowSearchByName,
      allowSearchByEmail: allowSearchByEmail,
      allowSearchById: allowSearchById,
    );
  }
}
