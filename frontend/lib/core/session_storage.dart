import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class SessionStorage {
  static const _sessionKey = 'auth_session';
  static const _rememberedLoginKey = 'remembered_login';

  Future<void> saveSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionKey,
      jsonEncode({
        'id': user.id,
        'email': user.email,
        'role': user.role.name,
        'token': user.token,
      }),
    );
  }

  Future<void> saveRememberedLogin(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rememberedLoginKey, value.trim().toLowerCase());
  }

  Future<String?> loadRememberedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_rememberedLoginKey)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  Future<AppUser?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final json = jsonDecode(raw) as Map<String, dynamic>;
    final roleName = json['role'] as String? ?? 'operator';

    return AppUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: roleName == 'admin' ? UserRole.admin : UserRole.operator,
      token: json['token'] as String? ?? '',
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
