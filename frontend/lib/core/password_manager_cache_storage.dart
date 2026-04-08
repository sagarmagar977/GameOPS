import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PasswordManagerCacheStorage {
  static const _passwordManagerCacheKey = 'password_manager_cache';

  Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_passwordManagerCacheKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordManagerCacheKey, jsonEncode(payload));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passwordManagerCacheKey);
  }
}
