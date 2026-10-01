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

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signIn(email: email, password: password);
      if (_currentUser != null) {
        await SecurityService().initEncryption(_currentUser!.uid);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String displayName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      if (_currentUser != null) {
        await SecurityService().initEncryption(_currentUser!.uid);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({String? displayName, String? photoUrl, String? statusMessage}) async {
    await _authService.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
      statusMessage: statusMessage,
    );
    _currentUser = _authService.currentUser;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
