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
  final VoidCallback onLogout;

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
                      _buildHeader(context, compact),
                      const SizedBox(height: 18),
                      Container(
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

  Widget _buildHeader(BuildContext context, bool compact) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18, vertical: compact ? 14 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE7EA)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildLogo(),
                    const SizedBox(width: 14),
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
                      tooltip: 'Log out',
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRoleChip(),
              ],
            )
          : Row(
              children: [
                _buildLogo(),
                const SizedBox(width: 14),
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
                _buildRoleChip(),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Log out',
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                ),
              ],
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
        '${user.username} - ${user.role.name}',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
