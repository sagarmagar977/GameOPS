import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiClient {
  const ApiClient();

  static String? _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<List<dynamic>> getList(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers());
    final body = _decode(response);
    return List<dynamic>.from(body['data'] as List<dynamic>);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/auth/login'),
      headers: _headers(includeJson: true),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    final body = _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String confirmPassword,
  ) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/auth/register'),
      headers: _headers(includeJson: true),
      body: jsonEncode({
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      }),
    );
    final body = _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> me() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/auth/me'),
      headers: _headers(),
    );
    final body = _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: _headers(includeJson: true),
      body: jsonEncode(payload),
    );
    final body = _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> payload) async {
    final response = await http.put(
      Uri.parse('$apiBaseUrl$path'),
      headers: _headers(includeJson: true),
      body: jsonEncode(payload),
    );
    final body = _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$apiBaseUrl$path'),
      headers: _headers(),
    );
    _decode(response);
  }

  Map<String, String> _headers({bool includeJson = false}) {
    final headers = <String, String>{};
    if (includeJson) {
      headers['Content-Type'] = 'application/json';
    }
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      final error = json['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'];
        final details = error['details'];

        if (details != null) {
          throw Exception('$message: $details');
        }

        throw Exception(message ?? 'Request failed');
      }

      throw Exception(json['message'] ?? 'Request failed');
    }
    return json;
  }
}
