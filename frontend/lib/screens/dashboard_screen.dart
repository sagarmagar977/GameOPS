import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/cashout.dart';
import '../models/cashout_rule.dart';
import '../models/game.dart';
import '../models/pending_cashout.dart';
import '../repositories/dashboard_repository.dart';
import '../services/pending_cashout_sync_service.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/page_frame.dart';

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
  final _repository = DashboardRepository();
  final _api = const ApiClient();
  final _pendingSyncService = PendingCashoutSyncService.instance;
  final playerNameController = TextEditingController();
  final amountController = TextEditingController();

  String? selectedGameId;
  bool isSavingCashout = false;
  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  String? _errorText;
  _DashboardData? _data;
  List<PendingCashout> _pendingCashouts = const [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    playerNameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    final pending = await _pendingSyncService.loadPending();
    final cachedJson = await _repository.loadCached();

    if (mounted) {
      setState(() {
        _pendingCashouts = pending;
      });
    }

    if (cachedJson != null && mounted) {
      setState(() {
        _data = _DashboardData.fromJson(cachedJson);
        _syncSelectedGameId(_data!.games);
        _isInitialLoading = false;
      });
    }

    if (mounted) {
      setState(() {
        _isRefreshing = true;
        _errorText = null;
      });
    }

    try {
      final syncedPending = await _pendingSyncService.syncPending();
      final remoteJson = await _repository.refreshRemote();
      final latestPending = await _pendingSyncService.loadPending();

      if (!mounted) {
        return;
      }

      setState(() {
        _data = _DashboardData.fromJson(remoteJson);
        _pendingCashouts = latestPending;
        _syncSelectedGameId(_data!.games);
        _isInitialLoading = false;
        _errorText = null;
      });

      if (syncedPending && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pending cashouts synced.')),
        );
      }
    } catch (error) {
      final latestPending = await _pendingSyncService.loadPending();
      if (!mounted) {
        return;
      }

      setState(() {
        _pendingCashouts = latestPending;
        _isInitialLoading = false;
        _errorText = '$error';
      });
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
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
        _errorText = null;
      });
    }
  }

  Future<void> _saveCashout() async {
    final playerName = playerNameController.text.trim();
    final amount = double.tryParse(amountController.text.trim());

    if (selectedGameId == null) {
      setState(() => _errorText = 'Choose a game first.');
      return;
    }
    if (playerName.isEmpty) {
      setState(() => _errorText = 'Username is required.');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _errorText = 'Enter a valid cashout amount.');
      return;
    }

    Game? selectedGame;
    for (final game in _data?.games ?? const <Game>[]) {
      if (game.id == selectedGameId) {
        selectedGame = game;
        break;
      }
    }

    setState(() {
      isSavingCashout = true;
      _errorText = null;
    });

    try {
      await _api.post('/cashouts', {
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
      });
      await _loadDashboard();
    } catch (error) {
      if (_isConnectivityError(error)) {
        await _pendingSyncService.enqueue(
          gameId: selectedGameId!,
          gameName: selectedGame?.name ?? 'Unknown game',
          playerName: playerName,
          amount: amount,
        );

        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        setState(() {
          playerNameController.clear();
          amountController.clear();
        });
        await _loadDashboard();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved offline. Cashout will sync automatically.')),
          );
        }
      } else {
        setState(() => _errorText = '$error');
      }
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
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    final data = _data;
    if (data == null) {
      if (_isInitialLoading) {
        return const DashboardSkeleton();
      }
      return Center(child: Text('Failed to load dashboard: ${_errorText ?? 'Unknown error'}'));
    }

    final mergedCashouts = _mergedCashouts(data.cashouts);
    final activeGames = data.games.where((game) => game.isActive).toList();
    final todayCashouts = mergedCashouts.where(_isToday).toList();
    final latestCashout = mergedCashouts.isEmpty ? null : mergedCashouts.first;
    final maxVisible = mergedCashouts.isEmpty
        ? 0.0
        : mergedCashouts.map((cashout) => cashout.amount).reduce((a, b) => a > b ? a : b);
    final minVisible = mergedCashouts.isEmpty
        ? 0.0
        : mergedCashouts.map((cashout) => cashout.amount).reduce((a, b) => a < b ? a : b);
    final todayCount = todayCashouts.length;
    final todayTotal = todayCashouts.fold<double>(0, (sum, cashout) => sum + cashout.amount);
    final latestAmount = latestCashout?.amount ?? 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 920;
        final stackLowerSections = constraints.maxWidth < 1040;

        return ListView(
          children: [
            if (_isRefreshing) const LinearProgressIndicator(),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                'Showing cached dashboard data. Refresh issue: $_errorText',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_pendingCashouts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${_pendingCashouts.length} cashout${_pendingCashouts.length == 1 ? '' : 's'} waiting to sync',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
              ),
            ],
            if (_isRefreshing || _errorText != null || _pendingCashouts.isNotEmpty) const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: compact ? 11 : 5,
                  child: _buildLiveGamesCard(activeGames),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: compact ? 13 : 7,
                  child: Column(
                    children: [
                      _buildCashoutSummaryCard(
                        todayCount: todayCount,
                        maxVisible: maxVisible,
                        minVisible: minVisible,
                        latestAmount: latestAmount,
                        todayTotal: todayTotal,
                        compact: compact,
                      ),
                      const SizedBox(height: 20),
                      _buildCashoutsCard(data.games, mergedCashouts),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (stackLowerSections) ...[
              _buildRulesCard(data.rules),
            ] else
              _buildRulesCard(data.rules),
          ],
        );
      },
    );
  }

  List<Cashout> _mergedCashouts(List<Cashout> remoteCashouts) {
    final pendingCashouts = _pendingCashouts.map((item) => item.toCashout());
    final merged = [...pendingCashouts, ...remoteCashouts];
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  void _syncSelectedGameId(List<Game> games) {
    if (selectedGameId != null && games.any((game) => game.id == selectedGameId)) {
      return;
    }
    selectedGameId = games.isNotEmpty ? games.first.id : null;
  }

  Widget _buildLiveGamesCard(List<Game> activeGames) {
    return _buildDashboardSection(
      title: 'Live Games',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statLine(
            label: 'Available now',
            value: activeGames.length.toString(),
            highlight: true,
          ),
          const SizedBox(height: 12),
          if (activeGames.isEmpty)
            const Text('No games are switched on right now.')
          else
            Column(
              children: activeGames.map((game) {
                return _listRow(
                  title: game.name,
                  subtitle: game.websiteUrl.isEmpty ? game.slug : game.websiteUrl,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCashoutSummaryCard({
    required int todayCount,
    required double maxVisible,
    required double minVisible,
    required double latestAmount,
    required double todayTotal,
    required bool compact,
  }) {
    return _buildDashboardSection(
      title: 'Cashouts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$todayCount cashout${todayCount == 1 ? '' : 's'} recorded today',
            style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.62)),
          ),
          const SizedBox(height: 16),
          _pairedStatRow(
            leftLabel: 'Max',
            leftValue: maxVisible.toStringAsFixed(2),
            rightLabel: 'Min',
            rightValue: minVisible.toStringAsFixed(2),
            compact: compact,
          ),
          const SizedBox(height: 12),
          _pairedStatRow(
            leftLabel: 'Latest',
            leftValue: latestAmount.toStringAsFixed(2),
            rightLabel: 'Total',
            rightValue: todayTotal.toStringAsFixed(2),
            compact: compact,
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard(List<CashoutRule> rules) {
    return _buildDashboardSection(
      title: 'Cashout Rules',
      child: rules.isEmpty
          ? const Text('No cashout rules yet.')
          : Column(
              children: rules.map((rule) {
                return _listRow(
                  title: rule.gameName.isEmpty ? 'Unknown game' : rule.gameName,
                  subtitle:
                      'Min ${rule.payoutMin.toStringAsFixed(2)}  Max ${rule.payoutMax.toStringAsFixed(2)}',
                  trailing: _pill(
                    rule.isFreeplayEnabled ? 'Enabled' : 'Paused',
                    rule.isFreeplayEnabled ? Colors.green : Colors.grey,
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildCashoutsCard(List<Game> games, List<Cashout> cashouts) {
    return _buildDashboardSection(
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
                final isPendingSync = cashout.status == 'pending_sync';
                return _listRow(
                  title: cashout.playerName,
                  subtitle: isPendingSync
                      ? '${cashout.gameName}  Pending sync'
                      : '${cashout.gameName}  ${_formatDate(cashout.createdAt)}',
                  trailing: Text(
                    cashout.amount.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isPendingSync ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboardSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFDCE4E8)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _statLine({
    required String label,
    required String value,
    bool highlight = false,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.62)),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: highlight ? 30 : 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing,
        ],
      ],
    );
  }

  Widget _pairedStatRow({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
    required bool compact,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _statLine(
            label: leftLabel,
            value: leftValue,
          ),
        ),
        SizedBox(width: compact ? 14 : 20),
        Expanded(
          child: _statLine(
            label: rightLabel,
            value: rightValue,
          ),
        ),
      ],
    );
  }

  Widget _listRow({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFDCE4E8)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing,
          ],
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
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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

  bool _isConnectivityError(Object error) {
    return error.toString().contains('Unable to reach any backend');
  }
}

class _DashboardData {
  const _DashboardData({
    required this.games,
    required this.rules,
    required this.cashouts,
  });

  factory _DashboardData.fromJson(Map<String, dynamic> json) {
    final gamesJson = List<dynamic>.from(json['games'] as List<dynamic>? ?? const []);
    final rulesJson = List<dynamic>.from(json['rules'] as List<dynamic>? ?? const []);
    final cashoutsJson = List<dynamic>.from(json['cashouts'] as List<dynamic>? ?? const []);

    return _DashboardData(
      games: gamesJson.map((item) => Game.fromJson(item as Map<String, dynamic>)).toList(),
      rules: rulesJson.map((item) => CashoutRule.fromJson(item as Map<String, dynamic>)).toList(),
      cashouts: cashoutsJson.map((item) => Cashout.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  final List<Game> games;
  final List<CashoutRule> rules;
  final List<Cashout> cashouts;
}
