class Faq {
  const Faq({
    required this.id,
    required this.question,
    required this.answer,
    required this.tags,
    required this.approved,
    this.gameName = '',
  });

  final String id;
  final String question;
  final String answer;
  final List<String> tags;
  final bool approved;
  final String gameName;

  factory Faq.fromJson(Map<String, dynamic> json) {
    final game = json['games'] as Map<String, dynamic>?;
    return Faq(
      id: json['id'] as String,
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? []).map((tag) => tag.toString()).toList(),
      approved: json['approved'] as bool? ?? false,
      gameName: game?['name'] as String? ?? '',
    );
  }
}
