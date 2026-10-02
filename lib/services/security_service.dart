import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  static const String _defaultSalt = 'KINI_CHAT_E2EE_SECURE_SALT_2026';
  final enc.IV _iv = enc.IV.fromLength(16);

  Future<void> initEncryption([String? userSecretKey]) async {
    // Không bắt buộc phải có userSecretKey nữa vì mã hóa theo phòng chat an toàn hơn
  }

  String encryptForRoom(String plainText, String roomId) {
    try {
      final hashedKey = sha256.convert(utf8.encode('KiniRoom_${roomId}_Key_$_defaultSalt')).bytes;
      final key = enc.Key.fromBase64(base64Url.encode(hashedKey.sublist(0, 32)));
      final encrypter = enc.Encrypter(enc.AES(key));
      final encrypted = encrypter.encrypt(plainText, iv: _iv);
      return 'ENC:${encrypted.base64}';
    } catch (e) {
      return plainText;
    }
  }

  String decryptForRoom(String cipherText, String roomId) {
    if (!cipherText.startsWith('ENC:')) {
      return cipherText;
    }
    try {
      final hashedKey = sha256.convert(utf8.encode('KiniRoom_${roomId}_Key_$_defaultSalt')).bytes;
      final key = enc.Key.fromBase64(base64Url.encode(hashedKey.sublist(0, 32)));
      final encrypter = enc.Encrypter(enc.AES(key));
      final rawBase64 = cipherText.replaceFirst('ENC:', '');
      return encrypter.decrypt64(rawBase64, iv: _iv);
    } catch (e) {
      // Nếu không giải mã được theo key phòng, trả về nội dung gốc an toàn
      return cipherText.replaceFirst('ENC:', '');
    }
  }

  String encryptText(String plainText) => plainText;
  String decryptText(String cipherText) => cipherText.startsWith('ENC:') ? cipherText.replaceFirst('ENC:', '') : cipherText;

  // Băm một chiều chuỗi (dùng cho câu trả lời bảo mật và mật khẩu)
  String hashString(String input) {
    final bytes = utf8.encode(input.trim().toLowerCase());
    return sha256.convert(bytes).toString();
  }

  // Mã hóa mật khẩu bảo mật (phục vụ tính năng khôi phục qua câu hỏi bảo mật)
  String encryptPassword(String plainPassword) {
    try {
      final hashedKey = sha256.convert(utf8.encode('KiniAuth_PasswordKey_$_defaultSalt')).bytes;
      final key = enc.Key.fromBase64(base64Url.encode(hashedKey.sublist(0, 32)));
      final encrypter = enc.Encrypter(enc.AES(key));
      final encrypted = encrypter.encrypt(plainPassword, iv: _iv);
      return 'AUTH_ENC:${encrypted.base64}';
    } catch (e) {
      return plainPassword;
    }
  }

  // Giải mã mật khẩu khi người dùng xác thực đúng câu hỏi bảo mật
  String decryptPassword(String cipherText) {
    if (!cipherText.startsWith('AUTH_ENC:')) {
      return cipherText;
    }
    try {
      final hashedKey = sha256.convert(utf8.encode('KiniAuth_PasswordKey_$_defaultSalt')).bytes;
      final key = enc.Key.fromBase64(base64Url.encode(hashedKey.sublist(0, 32)));
      final encrypter = enc.Encrypter(enc.AES(key));
      final rawBase64 = cipherText.replaceFirst('AUTH_ENC:', '');
      return encrypter.decrypt64(rawBase64, iv: _iv);
    } catch (e) {
      return cipherText.replaceFirst('AUTH_ENC:', '');
    }
  }

  Future<void> clearLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
