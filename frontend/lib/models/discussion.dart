class Discussion {
  const Discussion({
    required this.id,
    required this.authorName,
    required this.content,
    required this.approved,
    this.gameName = '',
  });

  final String id;
  final String authorName;
  final String content;
  final bool approved;
  final String gameName;

  factory Discussion.fromJson(Map<String, dynamic> json) {
    final game = json['games'] as Map<String, dynamic>?;
    return Discussion(
      id: json['id'] as String,
      authorName: json['author_name'] as String? ?? '',
      content: json['content'] as String? ?? '',
      approved: json['approved'] as bool? ?? false,
      gameName: game?['name'] as String? ?? '',
    );
  }
}
