class Cashout {
  const Cashout({
    required this.id,
    required this.playerName,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.gameName = '',
  });

  final String id;
  final String playerName;
  final double amount;
  final String status;
  final DateTime createdAt;
  final String gameName;

  factory Cashout.fromJson(Map<String, dynamic> json) {
    final game = json['games'] as Map<String, dynamic>?;
    return Cashout(
      id: json['id'] as String,
      playerName: json['player_name'] as String? ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      gameName: game?['name'] as String? ?? '',
    );
  }
}
