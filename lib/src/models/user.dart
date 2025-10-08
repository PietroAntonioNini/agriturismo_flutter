/// Modello per l'utente autenticato
/// Contiene tutti i dati del profilo utente ricevuti da /api/auth/verify-token o /api/users/me
class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isActive,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      // Il backend restituisce first_name/last_name, non firstName/lastName
      firstName: (json['firstName'] ?? json['first_name']) as String,
      lastName: (json['lastName'] ?? json['last_name']) as String,
      role: json['role'] as String,
      // Il backend restituisce is_active, non isActive
      isActive: (json['isActive'] ?? json['is_active']) as bool,
      // Il backend restituisce last_login, non lastLogin
      lastLogin: (json['lastLogin'] ?? json['last_login']) != null 
          ? DateTime.parse((json['lastLogin'] ?? json['last_login']) as String)
          : null,
      // Il backend restituisce created_at, non createdAt
      createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']) as String),
      // Il backend restituisce updated_at, non updatedAt  
      updatedAt: DateTime.parse((json['updatedAt'] ?? json['updated_at']) as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, role: $role)';
  }
}
