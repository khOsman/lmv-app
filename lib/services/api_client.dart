import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

/// Thin HTTP client that attaches the DM's session token (issued by
/// POST /auth/login on the Node backend) to every request and decodes
/// JSON responses. Throws [ApiException] on network errors or non-2xx
/// status codes.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const _tokenKey = 'dm_session_token';
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await readToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool withAuth = true}) async {
    try {
      final res = await http.get(_uri(path, query), headers: await _headers(withAuth: withAuth));
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not reach the server. Check your connection.');
    }
  }

  Future<dynamic> post(String path, {Object? body, bool withAuth = true}) async {
    try {
      final res = await http.post(
        _uri(path),
        headers: await _headers(withAuth: withAuth),
        body: body == null ? null : jsonEncode(body),
      );
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not reach the server. Check your connection.');
    }
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String message = 'Request failed (${res.statusCode})';
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['message'] is String) message = body['message'] as String;
      } catch (_) {
        if (res.body.isNotEmpty) message = res.body;
      }
      throw ApiException(message, statusCode: res.statusCode);
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }
}
