class AppUser {
  final int? id;
  final String username;
  final String fullName;
  final String role;
  final bool isActive;

  AppUser({
    this.id,
    required this.username,
    required this.fullName,
    this.role = 'VENDEDOR',
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'role': role,
        'is_active': isActive ? 1 : 0,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'],
        username: map['username'],
        fullName: map['full_name'],
        role: map['role'] ?? 'VENDEDOR',
        isActive: map['is_active'] == 1,
      );
}
