class Credential {
  const Credential({
    required this.id,
    required this.gameId,
    required this.username,
    required this.password,
    required this.label,
    required this.isPrimary,
    required this.notes,
    this.gameName = '',
  });

  final String id;
  final String gameId;
  final String username;
  final String password;
  final String label;
  final bool isPrimary;
  final String notes;
  final String gameName;

  factory Credential.fromJson(Map<String, dynamic> json) {
    final game = json['games'] as Map<String, dynamic>?;
    return Credential(
      id: json['id'] as String,
      gameId: json['game_id'] as String,
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      label: json['label'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      gameName: game?['name'] as String? ?? '',
    );
  }
}
