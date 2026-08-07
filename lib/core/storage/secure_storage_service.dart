import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/auth_api.dart';

class SecureStorageService {
  static const _tokenKey = 'credinexo_access_token';
  static const _userKey = 'credinexo_user';
  static const _operationTimeout = Duration(seconds: 6);

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveSession(AuthSession session) async {
    await _storage
        .write(key: _tokenKey, value: session.accessToken)
        .timeout(_operationTimeout);
    await _storage
        .write(key: _userKey, value: jsonEncode(session.user.toJson()))
        .timeout(_operationTimeout);
  }

  Future<String?> readToken() =>
      _storage.read(key: _tokenKey).timeout(_operationTimeout);

  Future<AuthUser?> readUser() async {
    final raw = await _storage.read(key: _userKey).timeout(_operationTimeout);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasValidToken() async {
    try {
      final token = await readToken();
      if (token == null || token.trim().isEmpty) return false;
      return !_isExpired(token);
    } catch (_) {
      return false;
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey).timeout(_operationTimeout);
    await _storage.delete(key: _userKey).timeout(_operationTimeout);
  }

  bool _isExpired(String token) {
    try {
      final payload = token.split('.')[1];
      final normalized = base64Url.normalize(payload);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)))
          as Map<String, dynamic>;
      final exp = decoded['exp'];
      if (exp is! num) return true;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      return DateTime.now().isAfter(expiresAt);
    } catch (_) {
      return true;
    }
  }
}
