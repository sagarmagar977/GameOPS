class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.token,
  });

  final String id;
  final String email;
  final UserRole role;
  final String token;

  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromAuthResponse(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['user'] as Map);
    return AppUser.fromUserJson(
      user,
      token: json['token'] as String? ?? '',
    );
  }

  factory AppUser.fromUserJson(Map<String, dynamic> user, {required String token}) {
    final roleName = user['role'] as String? ?? 'operator';

    return AppUser(
      id: user['id'] as String? ?? '',
      email: user['email'] as String? ?? '',
      role: roleName == 'admin' ? UserRole.admin : UserRole.operator,
      token: token,
    );
  }
}

enum UserRole {
  admin,
  operator,
}
