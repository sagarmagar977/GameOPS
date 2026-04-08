import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class GamesCacheStorage {
  static const _gamesCacheKey = 'games_cache';

  Future<List<dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_gamesCacheKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return List<dynamic>.from(jsonDecode(raw) as List<dynamic>);
  }

  Future<void> save(List<dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gamesCacheKey, jsonEncode(payload));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gamesCacheKey);
  }
}
