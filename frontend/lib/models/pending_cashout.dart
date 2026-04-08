import 'cashout.dart';

class PendingCashout {
  const PendingCashout({
    required this.localId,
    required this.gameId,
    required this.gameName,
    required this.playerName,
    required this.amount,
    required this.createdAt,
    required this.retryCount,
  });

  final String localId;
  final String gameId;
  final String gameName;
  final String playerName;
  final double amount;
  final DateTime createdAt;
  final int retryCount;

  Map<String, dynamic> toJson() {
    return {
      'local_id': localId,
      'game_id': gameId,
      'game_name': gameName,
      'player_name': playerName,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
    };
  }

  factory PendingCashout.fromJson(Map<String, dynamic> json) {
    return PendingCashout(
      localId: json['local_id'] as String? ?? '',
      gameId: json['game_id'] as String? ?? '',
      gameName: json['game_name'] as String? ?? '',
      playerName: json['player_name'] as String? ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      retryCount: json['retry_count'] as int? ?? 0,
    );
  }

  PendingCashout copyWith({
    String? localId,
    String? gameId,
    String? gameName,
    String? playerName,
    double? amount,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return PendingCashout(
      localId: localId ?? this.localId,
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
      playerName: playerName ?? this.playerName,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Cashout toCashout() {
    return Cashout(
      id: 'local:$localId',
      playerName: playerName,
      amount: amount,
      status: 'pending_sync',
      createdAt: createdAt,
      gameName: gameName,
    );
  }
}
