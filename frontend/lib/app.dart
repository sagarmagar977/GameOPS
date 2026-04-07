import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/session_storage.dart';
import 'core/theme.dart';
import 'models/app_user.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

class GameOpsApp extends StatefulWidget {
  const GameOpsApp({super.key});

  @override
  State<GameOpsApp> createState() => _GameOpsAppState();
}

class _GameOpsAppState extends State<GameOpsApp> {
  final _api = const ApiClient();
  final _sessionStorage = SessionStorage();
  AppUser? currentUser;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final savedUser = await _sessionStorage.loadSession();

    if (savedUser == null) {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
      return;
    }

    ApiClient.setAuthToken(savedUser.token);

    try {
      final userJson = await _api.me();
      final restoredUser = AppUser.fromUserJson(userJson, token: savedUser.token);

      if (!mounted) {
        return;
      }

      setState(() {
        currentUser = restoredUser;
        _isInitializing = false;
      });
    } catch (_) {
      ApiClient.setAuthToken(null);
      await _sessionStorage.clearSession();

      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _handleLogin(AppUser user, bool rememberMe) async {
    ApiClient.setAuthToken(user.token);
    if (rememberMe) {
      await _sessionStorage.saveSession(user);
    } else {
      await _sessionStorage.clearSession();
    }

    if (!mounted) {
      return;
    }

    setState(() => currentUser = user);
  }

  Future<void> _handleLogout() async {
    ApiClient.setAuthToken(null);
    await _sessionStorage.clearSession();

    if (!mounted) {
      return;
    }

    setState(() => currentUser = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameOps',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: _isInitializing
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : currentUser == null
          ? LoginScreen(onLogin: _handleLogin)
          : HomeShell(user: currentUser!, onLogout: _handleLogout),
    );
  }
}
