import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'notification_service.dart';
import 'security_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // Stream of Auth State changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Helper chuyển đổi mã lỗi Firebase sang Tiếng Việt
  String _mapFirebaseError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Tên đăng nhập hoặc Email này đã được sử dụng. Vui lòng chọn tên khác.';
        case 'invalid-email':
          return 'Địa chỉ email không đúng định dạng.';
        case 'weak-password':
          return 'Mật khẩu quá yếu. Vui lòng nhập tối thiểu 8 ký tự.';
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với thông tin này.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Tên đăng nhập hoặc mật khẩu không chính xác.';
        case 'user-disabled':
          return 'Tài khoản này đã bị khóa.';
        case 'too-many-requests':
          return 'Bạn đã thử đăng nhập quá nhiều lần. Vui lòng thử lại sau ít phút.';
        case 'operation-not-allowed':
          return 'Đăng nhập Email chưa được bật trên Firebase Console.';
        case 'network-request-failed':
          return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại internet.';
        default:
          return e.message ?? 'Đã xảy ra lỗi xác thực (${e.code}).';
      }
    }
    return e.toString();
  }

  // Tìm Document người dùng theo Username hoặc Email
  Future<DocumentSnapshot<Map<String, dynamic>>?> findUserDoc(String identifier) async {
    final clean = identifier.trim().toLowerCase();
    if (clean.isEmpty) return null;

    if (clean.contains('@')) {
      final snap = await _firestore.collection('users').where('email', isEqualTo: clean).limit(1).get();
      if (snap.docs.isNotEmpty) return snap.docs.first;
    }

    final userSnap = await _firestore.collection('users').where('username', isEqualTo: clean).limit(1).get();
    if (userSnap.docs.isNotEmpty) return userSnap.docs.first;

    // Fallback: tìm theo email ảo
    final fallbackSnap = await _firestore.collection('users').where('email', isEqualTo: '$clean@kinichat.app').limit(1).get();
    if (fallbackSnap.docs.isNotEmpty) return fallbackSnap.docs.first;

    return null;
  }

  // Đăng nhập bằng Tên đăng nhập (hoặc Email) & Mật khẩu
  Future<UserModel?> signIn({
    required String loginIdentifier,
    required String password,
  }) async {
    try {
      final clean = loginIdentifier.trim().toLowerCase();
      String targetEmail = clean;

      if (!clean.contains('@')) {
        final doc = await findUserDoc(clean);
        if (doc != null && doc.data() != null) {
          targetEmail = doc.data()!['email'] ?? '$clean@kinichat.app';
        } else {
          targetEmail = '$clean@kinichat.app';
        }
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: targetEmail,
        password: password.trim(),
      );

      if (credential.user != null) {
        final doc = await _firestore.collection('users').doc(credential.user!.uid).get();
        if (doc.exists) {
          _currentUser = UserModel.fromMap(doc.data()!, doc.id);
        } else {
          final username = clean.contains('@') ? clean.split('@').first : clean;
          _currentUser = UserModel(
            uid: credential.user!.uid,
            email: credential.user!.email ?? targetEmail,
            username: username,
            displayName: credential.user!.displayName ?? username,
            photoUrl: credential.user!.photoURL ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(username)}&background=0284C7&color=fff',
            isOnline: true,
            lastSeen: DateTime.now(),
          );
          await _firestore.collection('users').doc(credential.user!.uid).set(_currentUser!.toMap());
        }

        await _updateOnlineStatus(true);
        await _syncFcmToken();

        // Lưu thông tin đăng nhập tự động cho những lần sau
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_login_identifier', clean);
          await prefs.setString('saved_login_password', SecurityService().encryptPassword(password.trim()));
        } catch (e) {
          debugPrint('Lỗi lưu phiên đăng nhập: $e');
        }

        return _currentUser;
      }
    } catch (e) {
      debugPrint('Lỗi đăng nhập: $e');
      throw Exception(_mapFirebaseError(e));
    }
    return null;
  }

  // Đăng ký tài khoản mới kèm câu hỏi bảo mật
  Future<UserModel?> register({
    required String username,
    required String password,
    required String displayName,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    try {
      final cleanUsername = username.trim().toLowerCase();

      // Kiểm tra tên đăng nhập hợp lệ
      final usernameReg = RegExp(r'^[a-zA-Z0-9._-]+$');
      if (!usernameReg.hasMatch(cleanUsername)) {
        throw Exception('Tên đăng nhập chỉ bao gồm chữ cái, số, dấu chấm, gạch dưới (_) hoặc ngang (-).');
      }

      // Kiểm tra tên đăng nhập đã tồn tại chưa
      final existingDoc = await findUserDoc(cleanUsername);
      if (existingDoc != null) {
        throw Exception('Tên đăng nhập "$cleanUsername" đã được sử dụng. Vui lòng chọn tên khác.');
      }

      final email = cleanUsername.contains('@') ? cleanUsername : '$cleanUsername@kinichat.app';
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password.trim(),
      );

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(displayName.trim());

        final answerHash = SecurityService().hashString(securityAnswer);
        final passHash = SecurityService().hashString(password.trim());
        final passEncrypted = SecurityService().encryptPassword(password.trim());

        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? email,
          username: cleanUsername,
          displayName: displayName.trim(),
          securityQuestion: securityQuestion,
          securityAnswerHash: answerHash,
          photoUrl: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=0284C7&color=fff',
          isOnline: true,
          lastSeen: DateTime.now(),
          shareLocation: false, // Mặc định không chia sẻ vị trí để bảo vệ quyền riêng tư
        );

        final data = newUser.toMap();
        data['passwordHash'] = passHash;
        data['passwordEncrypted'] = passEncrypted;

        await _firestore.collection('users').doc(user.uid).set(data);
        _currentUser = newUser;
        await _syncFcmToken();

        // Lưu thông tin đăng nhập tự động cho những lần sau
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('saved_login_identifier', cleanUsername);
          await prefs.setString('saved_login_password', SecurityService().encryptPassword(password.trim()));
        } catch (e) {
          debugPrint('Lỗi lưu phiên đăng ký: $e');
        }

        return _currentUser;
      }
    } catch (e) {
      debugPrint('Lỗi đăng ký: $e');
      throw Exception(_mapFirebaseError(e));
    }
    return null;
  }

  // Lấy câu hỏi bảo mật của tài khoản
  Future<String?> getSecurityQuestion(String identifier) async {
    final doc = await findUserDoc(identifier);
    if (doc == null || doc.data() == null) return null;
    return doc.data()!['securityQuestion'] as String?;
  }

  // Khôi phục mật khẩu bằng câu trả lời bảo mật
  Future<bool> recoverPasswordWithSecurityQuestion({
    required String loginIdentifier,
    required String securityAnswer,
    required String newPassword,
  }) async {
    final doc = await findUserDoc(loginIdentifier);
    if (doc == null || doc.data() == null) {
      throw Exception('Không tìm thấy tài khoản với tên đăng nhập hoặc email này.');
    }

    final data = doc.data()!;
    final savedHash = data['securityAnswerHash'] as String? ?? '';
    final enteredHash = SecurityService().hashString(securityAnswer);

    if (savedHash.isEmpty || savedHash != enteredHash) {
      throw Exception('Câu trả lời bảo mật không chính xác. Vui lòng kiểm tra lại.');
    }

    final email = data['email'] as String? ?? '';
    final encPass = data['passwordEncrypted'] as String?;
    String? oldPass;
    if (encPass != null) {
      oldPass = SecurityService().decryptPassword(encPass);
    }

    if (oldPass != null && oldPass.isNotEmpty) {
      try {
        final cred = await _auth.signInWithEmailAndPassword(email: email, password: oldPass);
        if (cred.user != null) {
          await cred.user!.updatePassword(newPassword.trim());
        }
      } catch (e) {
        debugPrint('Lỗi cập nhật mật khẩu Firebase Auth: $e');
      }
    }

    // Cập nhật lại hash & chuỗi mã hóa trong Firestore
    final newPassHash = SecurityService().hashString(newPassword.trim());
    final newPassEnc = SecurityService().encryptPassword(newPassword.trim());

    await _firestore.collection('users').doc(doc.id).update({
      'passwordHash': newPassHash,
      'passwordEncrypted': newPassEnc,
    });

    return true;
  }

  // Cập nhật thông tin khôi phục bảo mật
  Future<void> updateSecurityQuestion({
    required String uid,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    final answerHash = SecurityService().hashString(securityAnswer);
    await _firestore.collection('users').doc(uid).update({
      'securityQuestion': securityQuestion,
      'securityAnswerHash': answerHash,
    });
    await loadCurrentUserData();
  }

  // Tải thông tin tài khoản hiện tại (tự động đăng nhập lại nếu phiên đã được lưu)
  Future<UserModel?> loadCurrentUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          _currentUser = UserModel.fromMap(doc.data()!, doc.id);
          return _currentUser;
        }
      } catch (e) {
        debugPrint('Lỗi tải thông tin user: $e');
      }
    }

    // Nếu Firebase Auth chưa có phiên (ví dụ trên Windows hoặc vừa mở lại app), tự động đăng nhập từ phiên đã lưu
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('saved_login_identifier');
      final savedEncPass = prefs.getString('saved_login_password');
      if (savedId != null && savedEncPass != null && savedId.isNotEmpty && savedEncPass.isNotEmpty) {
        final decryptedPass = SecurityService().decryptPassword(savedEncPass);
        if (decryptedPass.isNotEmpty) {
          debugPrint('Tự động đăng nhập lại từ phiên lưu trữ cho: $savedId');
          return await signIn(loginIdentifier: savedId, password: decryptedPass);
        }
      }
    } catch (e) {
      debugPrint('Lỗi tự động đăng nhập từ bộ nhớ máy: $e');
    }

    return null;
  }

  // Cập nhật thông tin cá nhân (Đầy đủ các trường)
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
    String? statusMessage,
    String? gender,
    int? birthYear,
    String? hometown,
    String? maritalStatus,
    String? bio,
    String? job,
    bool? shareLocation,
    double? latitude,
    double? longitude,
  }) async {
    if (_auth.currentUser == null) return;
    final uid = _auth.currentUser!.uid;

    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (statusMessage != null) updates['statusMessage'] = statusMessage;
    if (gender != null) updates['gender'] = gender;
    if (birthYear != null) updates['birthYear'] = birthYear;
    if (hometown != null) updates['hometown'] = hometown;
    if (maritalStatus != null) updates['maritalStatus'] = maritalStatus;
    if (bio != null) updates['bio'] = bio;
    if (job != null) updates['job'] = job;
    if (shareLocation != null) updates['shareLocation'] = shareLocation;
    if (latitude != null) updates['latitude'] = latitude;
    if (longitude != null) updates['longitude'] = longitude;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
      await loadCurrentUserData();
    }
  }

  // Cập nhật trạng thái online
  Future<void> _updateOnlineStatus(bool isOnline) async {
    if (_auth.currentUser == null) return;
    try {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  // Đồng bộ FCM Token
  Future<void> _syncFcmToken() async {
    if (_auth.currentUser == null) return;
    try {
      final token = await NotificationService().getToken();
      if (token != null) {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
          'fcmToken': token,
        });
      }
    } catch (_) {}
  }

  // Đăng xuất (xóa phiên lưu trữ để không tự động đăng nhập nữa)
  Future<void> signOut() async {
    await _updateOnlineStatus(false);
    await _auth.signOut();
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_login_identifier');
      await prefs.remove('saved_login_password');
    } catch (_) {}
  }
}
