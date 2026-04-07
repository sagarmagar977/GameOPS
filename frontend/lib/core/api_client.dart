import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiClient {
  const ApiClient();

  Future<List<dynamic>> getList(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);
    final response = await http.get(uri);
    final body = _decode(response);
    return List<dynamic>.from(body['data'] as List<dynamic>);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    final body = _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> payload) async {
    final response = await http.put(
      Uri.parse('$apiBaseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    final body = _decode(response);
    return Map<String, dynamic>.from(body['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String path) async {
    final response = await http.delete(Uri.parse('$apiBaseUrl$path'));
    _decode(response);
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
