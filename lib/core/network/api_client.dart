// core/network/api_client.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // or your token storage package

class ApiClient {
  // TODO: replace with your real API base URL (or read it from ApiConstants)
  static const String baseUrl = 'http://192.168.1.23:8000/api';

  Future<String?> _getToken() async {
    // TODO: replace with however your app stores the auth token.
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$cleanPath').replace(
      queryParameters: (query != null && query.isNotEmpty) ? query : null,
    );
  }

  Future<http.Response> get(String path, {Map<String, String>? query}) async {
    return http.get(_uri(path, query), headers: await _headers());
  }

  Future<http.Response> post(String path, {Object? body, Map<String, String>? query}) async {
    return http.post(
      _uri(path, query),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> patch(String path, {Object? body, Map<String, String>? query}) async {
    return http.patch(
      _uri(path, query),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> put(String path, {Object? body, Map<String, String>? query}) async {
    return http.put(
      _uri(path, query),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> delete(String path, {Object? body, Map<String, String>? query}) async {
    return http.delete(
      _uri(path, query),
      headers: await _headers(),
      body: body == null ? null : jsonEncode(body),
    );
  }
}