import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, SecureStorageService? storage})
      : _http = httpClient ?? http.Client(),
        _storage = storage ?? SecureStorageService();

  static const _requestTimeout = Duration(seconds: 20);

  final http.Client _http;
  final SecureStorageService _storage;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final base = Uri.parse(ApiConfig.baseUrl);
    return base.replace(
      path: '${base.path == '/' ? '' : base.path}$normalizedPath',
      queryParameters: query?.map((key, value) => MapEntry(key, '$value')),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    return _send(() async {
      return _http
          .get(_uri(path, query), headers: await _headers())
          .timeout(_requestTimeout);
    });
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    return _send(() async {
      return _http
          .post(
            _uri(path),
            headers: await _headers(),
            body: jsonEncode(body ?? {}),
          )
          .timeout(_requestTimeout);
    });
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    return _send(() async {
      return _http
          .patch(
            _uri(path),
            headers: await _headers(),
            body: jsonEncode(body ?? {}),
          )
          .timeout(_requestTimeout);
    });
  }

  Future<Map<String, String>> _headers() async {
    final token = await _storage.readToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Credinexo-App': 'mobile',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      return _decode(response);
    } on TimeoutException {
      throw const ApiException(
          'El servidor no respondio a tiempo. Intente nuevamente.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
          'No hay conexion con el servidor. Intente nuevamente.');
    }
  }

  dynamic _decode(http.Response response) {
    final body = response.body.trim();
    final decoded = body.isEmpty ? null : _safeJsonDecode(body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = decoded is Map<String, dynamic>
        ? _messageFromBody(decoded)
        : 'No hay conexion con el servidor. Intente nuevamente.';
    throw ApiException(message, statusCode: response.statusCode);
  }

  String _messageFromBody(Map<String, dynamic> body) {
    final raw = body['message'] ?? body['error'];
    if (raw is List) return raw.join(', ');
    if (raw is String && raw.trim().isNotEmpty) return raw;
    return 'No se pudo completar la solicitud.';
  }

  dynamic _safeJsonDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      throw const ApiException('El servidor devolvio una respuesta invalida.');
    }
  }
}
