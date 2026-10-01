import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

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
          return 'Email này đã được sử dụng. Vui lòng đăng nhập hoặc chọn email khác.';
        case 'invalid-email':
          return 'Địa chỉ email không đúng định dạng.';
        case 'weak-password':
          return 'Mật khẩu quá yếu. Vui lòng nhập tối thiểu 6 ký tự.';
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email hoặc mật khẩu không chính xác.';
        case 'user-disabled':
          return 'Tài khoản này đã bị khóa.';
        case 'too-many-requests':
          return 'Bạn đã thử đăng nhập quá nhiều lần. Vui lòng thử lại sau ít phút.';
        case 'operation-not-allowed':
          return 'Đăng nhập Email chưa được bật trên Firebase Console (Authentication > Sign-in method).';
        case 'network-request-failed':
          return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại internet.';
        default:
          return e.message ?? 'Đã xảy ra lỗi xác thực (${e.code}).';
      }
    }
    return e.toString();
  }

  // Đăng nhập bằng Email & Mật khẩu
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        final doc = await _firestore.collection('users').doc(credential.user!.uid).get();
        if (doc.exists) {
          _currentUser = UserModel.fromMap(doc.data()!, doc.id);
        } else {
          // Fallback nếu tài khoản auth có nhưng chưa có profile firestore
          _currentUser = UserModel(
            uid: credential.user!.uid,
            email: credential.user!.email ?? email,
            displayName: credential.user!.displayName ?? email.split('@').first,
            photoUrl: credential.user!.photoURL ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(email.split('@').first)}&background=random',
            isOnline: true,
            lastSeen: DateTime.now(),
          );
          await _firestore.collection('users').doc(credential.user!.uid).set(_currentUser!.toMap());
        }

        await _updateOnlineStatus(true);
        await _syncFcmToken();
        return _currentUser;
      }
    } catch (e) {
      debugPrint('Lỗi đăng nhập: $e');
      throw Exception(_mapFirebaseError(e));
    }
    return null;
  }

  // Đăng ký tài khoản mới
  Future<UserModel?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(displayName);

        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? email,
          displayName: displayName,
          photoUrl: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(displayName)}&background=random',
          isOnline: true,
          lastSeen: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        _currentUser = newUser;
        await _syncFcmToken();
        return _currentUser;
      }
    } catch (e) {
      debugPrint('Lỗi đăng ký: $e');
      throw Exception(_mapFirebaseError(e));
    }
    return null;
  }

  // Tải thông tin tài khoản hiện tại
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
    return null;
  }

  // Cập nhật thông tin cá nhân
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
    String? statusMessage,
    String? gender,
    int? birthYear,
    String? hometown,
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

    await _firestore.collection('users').doc(uid).update(updates);

    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        displayName: displayName,
        photoUrl: photoUrl,
        statusMessage: statusMessage,
        gender: gender,
        birthYear: birthYear,
        hometown: hometown,
      );
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

  // Đăng xuất
  Future<void> signOut() async {
    await _updateOnlineStatus(false);
    await _auth.signOut();
    _currentUser = null;
  }
}
