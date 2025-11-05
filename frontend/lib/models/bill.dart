class Admin {
  final int? id;
  final String username;
  final String password;
  final String email;
  final String fullName;
  final DateTime createdAt;
  final DateTime? lastLogin;

  Admin({
    this.id,
    required this.username,
    required this.password,
    required this.email,
    required this.fullName,
    required this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
      'fullName': fullName,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      email: map['email'],
      fullName: map['fullName'],
      createdAt: DateTime.parse(map['createdAt']),
      lastLogin: map['lastLogin'] != null ? DateTime.parse(map['lastLogin']) : null,
    );
  }

  Admin copyWith({
    int? id,
    String? username,
    String? password,
    String? email,
    String? fullName,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return Admin(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
