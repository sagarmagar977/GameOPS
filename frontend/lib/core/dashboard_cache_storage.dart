import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DashboardCacheStorage {
  static const _dashboardCacheKey = 'dashboard_cache';

  Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dashboardCacheKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dashboardCacheKey, jsonEncode(payload));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dashboardCacheKey);
  }
}
