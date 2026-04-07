import 'package:flutter/material.dart';

import '../models/app_user.dart';
import 'dashboard_screen.dart';
import 'games_screen.dart';
import 'knowledge_screen.dart';
import 'password_manager_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.user,
    required this.onLogout,
  });

  final AppUser user;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEAF5F6), Color(0xFFF5FAFB), Color(0xFFE8F1F7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 700;

                return Padding(
                  padding: EdgeInsets.fromLTRB(compact ? 12 : 20, 18, compact ? 12 : 20, compact ? 12 : 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.78),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFDCE7EA)),
                              ),
                              child: const TabBar(
                                indicatorSize: TabBarIndicatorSize.tab,
                                tabs: [
                                  Tab(icon: Icon(Icons.dashboard_outlined)),
                                  Tab(icon: Icon(Icons.sports_esports_outlined)),
                                  Tab(icon: Icon(Icons.password_outlined)),
                                  Tab(icon: Icon(Icons.search_outlined)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildProfileButton(context),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: TabBarView(
                          children: [
                            DashboardScreen(isAdmin: user.isAdmin),
                            GamesScreen(isAdmin: user.isAdmin),
                            PasswordManagerScreen(isAdmin: user.isAdmin),
                            KnowledgeScreen(isAdmin: user.isAdmin),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => _showProfileCard(context),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.84),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE7EA)),
        ),
        child: _buildLogo(),
      ),
    );
  }

  Future<void> _showProfileCard(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDCE7EA)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildLogo(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GameOps', style: Theme.of(context).textTheme.titleLarge),
                        Text(
                          user.isAdmin ? 'Admin control panel' : 'Operator view',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildRoleChip(),
              const SizedBox(height: 12),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await onLogout();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0A7E6C).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.stadium_outlined),
    );
  }

  Widget _buildRoleChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${user.email} - ${user.role.name}',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
