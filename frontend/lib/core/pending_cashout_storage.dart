import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pending_cashout.dart';

class PendingCashoutStorage {
  static const _pendingCashoutsKey = 'pending_cashouts';

  Future<List<PendingCashout>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingCashoutsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final json = List<dynamic>.from(jsonDecode(raw) as List<dynamic>);
    return json.map((item) => PendingCashout.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> save(List<PendingCashout> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingCashoutsKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingCashoutsKey);
  }
}
