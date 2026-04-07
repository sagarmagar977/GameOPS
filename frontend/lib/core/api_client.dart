import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiClient {
  const ApiClient();

  static String? _authToken;
  static String? _preferredBaseUrl;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<List<dynamic>> getList(String path, {Map<String, String>? query}) async {
    final response = await _send(
      path,
      (baseUrl) => http.get(
        Uri.parse('$baseUrl$path').replace(queryParameters: query),
        headers: _headers(),
      ),
    );
    final body = _decode(response);
    return List<dynamic>.from(body['data'] as List<dynamic>);
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) async {
    final response = await _send(
      path,
      (baseUrl) => http.get(
        Uri.parse('$baseUrl$path').replace(queryParameters: query),
        headers: _headers(),
      ),
    );
    final body = _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _send(
      '/auth/login',
      (baseUrl) => http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers(includeJson: true),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ),
    );
    final body = _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String confirmPassword,
  ) async {
    final response = await _send(
      '/auth/register',
      (baseUrl) => http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers(includeJson: true),
        body: jsonEncode({
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
        }),
      ),
    );
    final body = _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _send(
      '/auth/me',
      (baseUrl) => http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers(),
      ),
    );
    final body = _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> payload) async {
    final response = await _send(
      path,
      (baseUrl) => http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers(includeJson: true),
        body: jsonEncode(payload),
      ),
    );
    final body = _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> payload) async {
    final response = await _send(
      path,
      (baseUrl) => http.put(
        Uri.parse('$baseUrl$path'),
        headers: _headers(includeJson: true),
        body: jsonEncode(payload),
      ),
    );
    final body = _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String path) async {
    final response = await _send(
      path,
      (baseUrl) => http.delete(
        Uri.parse('$baseUrl$path'),
        headers: _headers(),
      ),
    );
    _decode(response);
  }

  Future<http.Response> _send(
    String path,
    Future<http.Response> Function(String baseUrl) request,
  ) async {
    final urls = _candidateBaseUrls();
    Object? lastError;

    for (final baseUrl in urls) {
      try {
        final response = await request(baseUrl);
        _preferredBaseUrl = baseUrl;
        return response;
      } on SocketException catch (error) {
        lastError = error;
      } on http.ClientException catch (error) {
        lastError = error;
      }
    }

    throw Exception(
      'Unable to reach any backend for $path. Last error: $lastError',
    );
  }

  List<String> _candidateBaseUrls() {
    final urls = apiBaseUrls;
    final preferred = _preferredBaseUrl;
    if (preferred == null || !urls.contains(preferred)) {
      return urls;
    }

    return [preferred, ...urls.where((url) => url != preferred)];
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
