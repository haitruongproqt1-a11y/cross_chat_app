import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/security_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authService.loadCurrentUserData();
      if (_currentUser != null) {
        await SecurityService().initEncryption(_currentUser!.uid);
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<UserModel?> loadCurrentUserData() async {
    _currentUser = await _authService.loadCurrentUserData();
    notifyListeners();
    return _currentUser;
  }

  Future<bool> signIn(String loginIdentifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signIn(
        loginIdentifier: loginIdentifier,
        password: password,
      );
      if (_currentUser != null) {
        await SecurityService().initEncryption(_currentUser!.uid);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String password,
    required String displayName,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.register(
        username: username,
        password: password,
        displayName: displayName,
        securityQuestion: securityQuestion,
        securityAnswer: securityAnswer,
      );
      if (_currentUser != null) {
        await SecurityService().initEncryption(_currentUser!.uid);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> getSecurityQuestion(String identifier) async {
    try {
      return await _authService.getSecurityQuestion(identifier);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    }
  }

  Future<bool> recoverPassword({
    required String loginIdentifier,
    required String securityAnswer,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.recoverPasswordWithSecurityQuestion(
        loginIdentifier: loginIdentifier,
        securityAnswer: securityAnswer,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSecurityQuestion({
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.updateSecurityQuestion(
        uid: _currentUser!.uid,
        securityQuestion: securityQuestion,
        securityAnswer: securityAnswer,
      );
      _currentUser = _authService.currentUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

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
    await _authService.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
      statusMessage: statusMessage,
      gender: gender,
      birthYear: birthYear,
      hometown: hometown,
      maritalStatus: maritalStatus,
      bio: bio,
      job: job,
      shareLocation: shareLocation,
      latitude: latitude,
      longitude: longitude,
    );
    _currentUser = _authService.currentUser;
    notifyListeners();
  }

  void updateBubbleThemeId(String bubbleThemeId) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(bubbleThemeId: bubbleThemeId);
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
