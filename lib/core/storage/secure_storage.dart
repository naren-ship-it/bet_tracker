import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _tokenKey = 'access_token';
  static const String _resetTokenKey = 'password_reset_token';

  // ───────────────────────────────────────────────────────────────────────────
  // ACCESS TOKEN
  // ───────────────────────────────────────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    await _storage.write(
      key: _tokenKey,
      value: token,
    );
  }

  static Future<String?> getToken() async {
    return await _storage.read(
      key: _tokenKey,
    );
  }

  static Future<void> deleteToken() async {
    await _storage.delete(
      key: _tokenKey,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PASSWORD RESET TOKEN
  // ───────────────────────────────────────────────────────────────────────────

  static Future<void> saveResetToken(String token) async {
    await _storage.write(
      key: _resetTokenKey,
      value: token,
    );
  }

  static Future<String?> getResetToken() async {
    return await _storage.read(
      key: _resetTokenKey,
    );
  }

  static Future<void> deleteResetToken() async {
    await _storage.delete(
      key: _resetTokenKey,
    );
  }
}