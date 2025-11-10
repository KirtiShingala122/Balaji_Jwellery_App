class Admin {
  final int? id;
  final String username;
  final String email;
  final String fullName;
  final String password;

  Admin({
    this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.password,
  });

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['id'],
      username: map['username'],
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      password: map['password'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'password': password,
    };
  }
}
