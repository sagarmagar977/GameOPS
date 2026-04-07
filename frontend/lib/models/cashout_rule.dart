class CashoutRule {
  const CashoutRule({
    required this.id,
    required this.gameId,
    required this.freeplayLabel,
    required this.payoutMin,
    required this.payoutMax,
    required this.slopePercent,
    required this.isFreeplayEnabled,
    required this.notes,
    this.gameName = '',
  });

  final String id;
  final String gameId;
  final String freeplayLabel;
  final double payoutMin;
  final double payoutMax;
  final double slopePercent;
  final bool isFreeplayEnabled;
  final String notes;
  final String gameName;

  factory CashoutRule.fromJson(Map<String, dynamic> json) {
    final game = json['games'] as Map<String, dynamic>?;
    return CashoutRule(
      id: json['id'] as String,
      gameId: json['game_id'] as String,
      freeplayLabel: json['freeplay_label'] as String? ?? '',
      payoutMin: double.tryParse(json['payout_min'].toString()) ?? 0,
      payoutMax: double.tryParse(json['payout_max'].toString()) ?? 0,
      slopePercent: double.tryParse(json['slope_percent'].toString()) ?? 0,
      isFreeplayEnabled: json['is_freeplay_enabled'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      gameName: game?['name'] as String? ?? '',
    );
  }
}
