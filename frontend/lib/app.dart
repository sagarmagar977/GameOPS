import 'package:flutter/material.dart';

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
  AppUser? currentUser;

  void _handleLogin(AppUser user) {
    setState(() => currentUser = user);
  }

  void _handleLogout() {
    setState(() => currentUser = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameOps',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: currentUser == null
          ? LoginScreen(onLogin: _handleLogin)
          : HomeShell(user: currentUser!, onLogout: _handleLogout),
    );
  }
}
