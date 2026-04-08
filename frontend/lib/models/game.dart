class Game {
  const Game({
    required this.id,
    required this.name,
    required this.slug,
    required this.websiteUrl,
    required this.isActive,
    required this.isHighlighted,
    required this.notes,
  });

  final String id;
  final String name;
  final String slug;
  final String websiteUrl;
  final bool isActive;
  final bool isHighlighted;
  final String notes;

  Game copyWith({
    String? id,
    String? name,
    String? slug,
    String? websiteUrl,
    bool? isActive,
    bool? isHighlighted,
    String? notes,
  }) {
    return Game(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      isActive: isActive ?? this.isActive,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      notes: notes ?? this.notes,
    );
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      websiteUrl: json['website_url'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      isHighlighted: json['is_highlighted'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
    );
  }
}
