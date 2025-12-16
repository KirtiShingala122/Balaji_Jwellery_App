class Admin {
  final int? id;
  final String username;
  final String email;
  final String fullName;
  final String password;
  final String? phoneNumber;
  final String? address;

  Admin({
    this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.password,
    this.phoneNumber,
    this.address,
  });

  factory Admin.fromMap(Map<String, dynamic> map) {
    return Admin(
      id: map['id'],
      username: map['username'],
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      password: map['password'] ?? '',
      phoneNumber: map['phoneNumber'],
      address: map['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'password': password,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }
}
