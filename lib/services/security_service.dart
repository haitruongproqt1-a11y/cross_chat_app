import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  // 32-character AES Key
  static const String _defaultSalt = 'CrossChatApp_Secure_Salt_2026';
  enc.Encrypter? _encrypter;
  final enc.IV _iv = enc.IV.fromLength(16);

  Future<void> initEncryption([String? userSecretKey]) async {
    final keySource = userSecretKey ?? _defaultSalt;
    final hashedKey = sha256.convert(utf8.encode(keySource)).bytes;
    final key = enc.Key.fromBase64(base64Url.encode(hashedKey.sublist(0, 32)));
    _encrypter = enc.Encrypter(enc.AES(key));
  }

  String encryptText(String plainText) {
    if (_encrypter == null) return plainText;
    try {
      final encrypted = _encrypter!.encrypt(plainText, iv: _iv);
      return 'ENC:${encrypted.base64}';
    } catch (e) {
      return plainText;
    }
  }

  String decryptText(String cipherText) {
    if (_encrypter == null || !cipherText.startsWith('ENC:')) {
      return cipherText;
    }
    try {
      final rawBase64 = cipherText.replaceFirst('ENC:', '');
      final decrypted = _encrypter!.decrypt64(rawBase64, iv: _iv);
      return decrypted;
    } catch (e) {
      return '[Encrypted message cannot be decrypted]';
    }
  }

  Future<void> clearLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
