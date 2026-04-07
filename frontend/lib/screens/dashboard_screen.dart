import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/cashout.dart';
import '../models/cashout_rule.dart';
import '../models/game.dart';
import '../widgets/page_frame.dart';
import '../widgets/section_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.isAdmin,
  });

  final bool isAdmin;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final api = const ApiClient();
  final playerNameController = TextEditingController();
  final amountController = TextEditingController();

  String? selectedGameId;
  bool isSavingCashout = false;
  String? errorText;
  int _reloadSeed = 0;

  @override
  void dispose() {
    playerNameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<_DashboardData> _load() async {
    final dashboardJson = await api.get('/dashboard');
    final gamesJson = List<dynamic>.from(dashboardJson['games'] as List<dynamic>);
    final rulesJson = List<dynamic>.from(dashboardJson['rules'] as List<dynamic>);
    final cashoutsJson = List<dynamic>.from(dashboardJson['cashouts'] as List<dynamic>);

    final games = gamesJson.map((item) => Game.fromJson(item as Map<String, dynamic>)).toList();
    final rules = rulesJson.map((item) => CashoutRule.fromJson(item as Map<String, dynamic>)).toList();
    final cashouts = cashoutsJson.map((item) => Cashout.fromJson(item as Map<String, dynamic>)).toList();

    selectedGameId ??= games.isNotEmpty ? games.first.id : null;

    return _DashboardData(games: games, rules: rules, cashouts: cashouts);
  }

  Future<void> _openCashoutSheet(List<Game> games) async {
    if (games.isNotEmpty) {
      selectedGameId ??= games.first.id;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCashoutForm(games),
            ),
          ),
        );
      },
    );

    if (mounted) {
      setState(() {
        playerNameController.clear();
        amountController.clear();
        errorText = null;
      });
    }
  }

  Future<void> _saveCashout() async {
    final playerName = playerNameController.text.trim();
    final amount = double.tryParse(amountController.text.trim());

    if (selectedGameId == null) {
      setState(() => errorText = 'Choose a game first.');
      return;
    }
    if (playerName.isEmpty) {
      setState(() => errorText = 'Username is required.');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => errorText = 'Enter a valid cashout amount.');
      return;
    }

    setState(() {
      isSavingCashout = true;
      errorText = null;
    });

    try {
      await api.post('/cashouts', {
        'game_id': selectedGameId,
        'credential_id': null,
        'player_name': playerName,
        'amount': amount,
        'status': 'completed',
        'notes': '',
      });

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() {
        playerNameController.clear();
        amountController.clear();
        _reloadSeed++;
      });
    } catch (error) {
      setState(() => errorText = '$error');
    } finally {
      if (mounted) {
        setState(() => isSavingCashout = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: widget.isAdmin ? 'Operations Dashboard' : 'Operator Dashboard',
      subtitle: widget.isAdmin
          ? 'See which games are live and track cashouts from the database.'
          : 'Check available games and read the latest cashout summary.',
      child: FutureBuilder<_DashboardData>(
        future: _load(),
        key: ValueKey(_reloadSeed),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return Center(child: Text('Failed to load dashboard: ${snapshot.error}'));
            }
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final activeGames = data.games.where((game) => game.isActive).toList();
          final todayCashouts = data.cashouts.where(_isToday).toList();
          final latestCashout = data.cashouts.isEmpty ? null : data.cashouts.first;
          final maxToday = todayCashouts.isEmpty
              ? 0.0
              : todayCashouts.map((cashout) => cashout.amount).reduce((a, b) => a > b ? a : b);
          final minToday = todayCashouts.isEmpty
              ? 0.0
              : todayCashouts.map((cashout) => cashout.amount).reduce((a, b) => a < b ? a : b);
          final todayCount = todayCashouts.length;
          final todayTotal = todayCashouts.fold<double>(0, (sum, cashout) => sum + cashout.amount);
          final latestAmount = latestCashout?.amount ?? 0.0;

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 920;

              return ListView(
                children: [
                  compact
                      ? Column(
                          children: [
                            _buildLiveGamesCard(activeGames),
                            const SizedBox(height: 16),
                            _buildCashoutSummaryCard(
                              todayCount: todayCount,
                              maxToday: maxToday,
                              minToday: minToday,
                              latestAmount: latestAmount,
                              todayTotal: todayTotal,
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _buildLiveGamesCard(activeGames),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 8,
                              child: _buildCashoutSummaryCard(
                                todayCount: todayCount,
                                maxToday: maxToday,
                                minToday: minToday,
                                latestAmount: latestAmount,
                                todayTotal: todayTotal,
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 20),
                  _buildAvailableGamesCard(activeGames),
                  const SizedBox(height: 20),
                  if (compact) ...[
                    _buildRulesCard(data.rules),
                    const SizedBox(height: 20),
                    _buildCashoutsCard(data.games, data.cashouts),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildRulesCard(data.rules)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildCashoutsCard(data.games, data.cashouts)),
                      ],
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _metricCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE4E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.62))),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildLiveGamesCard(List<Game> activeGames) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE4E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Games',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(
            activeGames.length.toString(),
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            activeGames.isEmpty
                ? 'No games are currently active.'
                : 'Games currently available to operators.',
            style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.62)),
          ),
        ],
      ),
    );
  }

  Widget _buildCashoutSummaryCard({
    required int todayCount,
    required double maxToday,
    required double minToday,
    required double latestAmount,
    required double todayTotal,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE4E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Cashouts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '$todayCount cashout${todayCount == 1 ? '' : 's'} recorded today',
            style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.62)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _metricCard('Max Cashout', maxToday.toStringAsFixed(2))),
              const SizedBox(width: 12),
              Expanded(child: _metricCard('Min Cashout', minToday.toStringAsFixed(2))),
              const SizedBox(width: 12),
              Expanded(child: _metricCard('Latest Cashout', latestAmount.toStringAsFixed(2))),
            ],
          ),
          const SizedBox(height: 12),
          _metricCard('Total Cashouts', todayTotal.toStringAsFixed(2)),
        ],
      ),
    );
  }

  Widget _buildAvailableGamesCard(List<Game> activeGames) {
    return SectionCard(
      title: 'Available Games',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDCE4E8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available now',
                        style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.62)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activeGames.length.toString(),
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                _pill(activeGames.isEmpty ? 'Offline' : 'Live', activeGames.isEmpty ? Colors.grey : Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (activeGames.isEmpty)
            const Text('No games are switched on right now.')
          else
            Column(
              children: activeGames.map((game) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _dashboardRow(
                    title: game.name,
                    subtitle: game.websiteUrl.isEmpty ? game.slug : game.websiteUrl,
                    trailing: _pill('Live', Colors.green),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRulesCard(List<CashoutRule> rules) {
    return SectionCard(
      title: 'Cashout Rules',
      child: rules.isEmpty
          ? const Text('No cashout rules yet.')
          : Column(
              children: rules.map((rule) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _dashboardRow(
                    title: rule.gameName.isEmpty ? 'Unknown game' : rule.gameName,
                    subtitle:
                        'Min ${rule.payoutMin.toStringAsFixed(2)}  Max ${rule.payoutMax.toStringAsFixed(2)}',
                    trailing: _pill(
                      rule.isFreeplayEnabled ? 'Enabled' : 'Paused',
                      rule.isFreeplayEnabled ? Colors.green : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildCashoutsCard(List<Game> games, List<Cashout> cashouts) {
    return SectionCard(
      title: 'Cashouts',
      child: Column(
        children: [
          if (widget.isAdmin)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${cashouts.length} cashout${cashouts.length == 1 ? '' : 's'} recorded',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openCashoutSheet(games),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          if (widget.isAdmin) const SizedBox(height: 14),
          if (cashouts.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('No cashouts yet.'),
            )
          else
            Column(
              children: cashouts.take(8).map((cashout) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _dashboardRow(
                    title: cashout.playerName,
                    subtitle: '${cashout.gameName}  ${_formatDate(cashout.createdAt)}',
                    trailing: Text(
                      cashout.amount.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _dashboardRow({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE4E8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.62)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }

  Widget _buildCashoutForm(List<Game> games) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Cashout', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Save one new cashout record to the database.', style: Theme.of(context).textTheme.bodyMedium),
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
        DropdownButtonFormField<String>(
          value: selectedGameId,
          items: games.map((game) => DropdownMenuItem(value: game.id, child: Text(game.name))).toList(),
          onChanged: (value) => setState(() => selectedGameId = value),
          decoration: const InputDecoration(labelText: 'Game'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: playerNameController,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Cashout amount'),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isSavingCashout ? null : _saveCashout,
            icon: const Icon(Icons.add),
            label: const Text('Create Cashout'),
          ),
        ),
      ],
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }

  bool _isToday(Cashout cashout) {
    final now = DateTime.now();
    final created = cashout.createdAt.toLocal();
    return created.year == now.year && created.month == now.month && created.day == now.day;
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }
}

class _DashboardData {
  const _DashboardData({
    required this.games,
    required this.rules,
    required this.cashouts,
  });

  final List<Game> games;
  final List<CashoutRule> rules;
  final List<Cashout> cashouts;
}
