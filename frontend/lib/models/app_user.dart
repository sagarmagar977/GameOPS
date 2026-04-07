class AppUser {
  const AppUser({
    required this.username,
    required this.role,
  });

  final String username;
  final UserRole role;

  bool get isAdmin => role == UserRole.admin;
}

enum UserRole {
  admin,
  operator,
}
