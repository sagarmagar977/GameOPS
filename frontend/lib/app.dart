import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/dashboard_cache_storage.dart';
import 'core/games_cache_storage.dart';
import 'core/knowledge_cache_storage.dart';
import 'core/password_manager_cache_storage.dart';
import 'core/session_storage.dart';
import 'services/pending_cashout_sync_service.dart';
import 'core/theme.dart';
import 'models/app_user.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

class GameOpsApp extends StatefulWidget {
  const GameOpsApp({super.key});

  @override
  State<GameOpsApp> createState() => _GameOpsAppState();
}

class _GameOpsAppState extends State<GameOpsApp> with WidgetsBindingObserver {
  final _api = const ApiClient();
  final _dashboardCacheStorage = DashboardCacheStorage();
  final _gamesCacheStorage = GamesCacheStorage();
  final _knowledgeCacheStorage = KnowledgeCacheStorage();
  final _passwordManagerCacheStorage = PasswordManagerCacheStorage();
  final _sessionStorage = SessionStorage();
  AppUser? currentUser;
  bool _isInitializing = true;
  String? _rememberedLogin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _restoreSession() async {
    final savedUser = await _sessionStorage.loadSession();
    final rememberedLogin = await _sessionStorage.loadRememberedLogin();

    if (mounted) {
      setState(() => _rememberedLogin = rememberedLogin);
    }

    if (savedUser == null) {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
      return;
    }

    ApiClient.setAuthToken(savedUser.token);
    if (mounted) {
      setState(() {
        currentUser = savedUser;
        _isInitializing = false;
      });
    }

    await PendingCashoutSyncService.instance.syncPending();
    _verifySession(savedUser);
  }

  Future<void> _verifySession(AppUser savedUser) async {
    try {
      final userJson = await _api.me();
      final restoredUser = AppUser.fromUserJson(userJson, token: savedUser.token);
      await _sessionStorage.saveSession(restoredUser);
      await _sessionStorage.saveRememberedLogin(restoredUser.email);

      if (!mounted || currentUser?.token != savedUser.token) {
        return;
      }

      setState(() {
        currentUser = restoredUser;
        _rememberedLogin = restoredUser.email;
      });
      await PendingCashoutSyncService.instance.syncPending();
    } catch (error) {
      if (_isConnectivityError(error)) {
        return;
      }

      ApiClient.setAuthToken(null);
      await _sessionStorage.clearSession();
      await _dashboardCacheStorage.clear();
      await _gamesCacheStorage.clear();
      await _knowledgeCacheStorage.clear();
      await _passwordManagerCacheStorage.clear();
      await PendingCashoutSyncService.instance.clear();

      if (!mounted || currentUser?.token != savedUser.token) {
        return;
      }

      setState(() => currentUser = null);
    }
  }

  Future<void> _handleLogin(AppUser user, bool rememberMe) async {
    ApiClient.setAuthToken(user.token);
    await _sessionStorage.saveRememberedLogin(user.email);
    if (rememberMe) {
      await _sessionStorage.saveSession(user);
    } else {
      await _sessionStorage.clearSession();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      currentUser = user;
      _rememberedLogin = user.email;
    });
    await PendingCashoutSyncService.instance.syncPending();
  }

  Future<void> _handleLogout() async {
    ApiClient.setAuthToken(null);
    await _sessionStorage.clearSession();
    await _dashboardCacheStorage.clear();
    await _gamesCacheStorage.clear();
    await _knowledgeCacheStorage.clear();
    await _passwordManagerCacheStorage.clear();
    await PendingCashoutSyncService.instance.clear();

    if (!mounted) {
      return;
    }

    setState(() => currentUser = null);
  }

  bool _isConnectivityError(Object error) {
    return error.toString().contains('Unable to reach any backend');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && currentUser != null) {
      PendingCashoutSyncService.instance.syncPending();
    }
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
          ? LoginScreen(
              onLogin: _handleLogin,
              initialEmail: _rememberedLogin,
            )
          : HomeShell(user: currentUser!, onLogout: _handleLogout),
    );
  }
}
