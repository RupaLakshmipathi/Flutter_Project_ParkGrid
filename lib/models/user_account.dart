import 'package:parkgrid/core/constants/app_enums.dart';

class UserAccount {
  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String passwordSalt;
  final UserRole role;

  UserAccount copyWith({
    String? id,
    String? name,
    String? email,
    String? passwordHash,
    String? passwordSalt,
    UserRole? role,
  }) {
    return UserAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'passwordSalt': passwordSalt,
      'role': role.name,
    };
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      // Older local snapshots stored the password in the `password` field.
      passwordHash: (json['passwordHash'] ?? json['password']) as String,
      passwordSalt: json['passwordSalt'] as String? ?? '',
      role: UserRole.values.byName(json['role'] as String),
    );
  }
}
