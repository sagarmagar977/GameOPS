import '../core/api_client.dart';
import '../core/pending_cashout_storage.dart';
import '../models/pending_cashout.dart';

class PendingCashoutSyncService {
  PendingCashoutSyncService._();

  static final PendingCashoutSyncService instance = PendingCashoutSyncService._();

  final _storage = PendingCashoutStorage();
  final _api = const ApiClient();
  bool _isSyncing = false;

  Future<List<PendingCashout>> loadPending() {
    return _storage.load();
  }

  Future<PendingCashout> enqueue({
    required String gameId,
    required String gameName,
    required String playerName,
    required double amount,
  }) async {
    final items = await _storage.load();
    final pending = PendingCashout(
      localId: DateTime.now().microsecondsSinceEpoch.toString(),
      gameId: gameId,
      gameName: gameName,
      playerName: playerName,
      amount: amount,
      createdAt: DateTime.now(),
      retryCount: 0,
    );
    await _storage.save([pending, ...items]);
    return pending;
  }

  Future<bool> syncPending() async {
    if (_isSyncing) {
      return false;
    }

    _isSyncing = true;
    var anySynced = false;
    try {
      var items = await _storage.load();
      if (items.isEmpty) {
        return false;
      }

      final remaining = <PendingCashout>[];
      for (final item in items) {
        try {
          await _api.post('/cashouts', {
            'game_id': item.gameId,
            'credential_id': null,
            'player_name': item.playerName,
            'amount': item.amount,
            'status': 'completed',
            'notes': '',
          });
          anySynced = true;
        } catch (error) {
          remaining.add(item.copyWith(retryCount: item.retryCount + 1));
          if (_isConnectivityError(error)) {
            final untouched = items.skip(items.indexOf(item) + 1);
            remaining.addAll(untouched);
            break;
          }
        }
      }

      await _storage.save(remaining);
      return anySynced;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> clear() {
    return _storage.clear();
  }

  bool _isConnectivityError(Object error) {
    return error.toString().contains('Unable to reach any backend');
  }
}
