class AppUser {
  final String id;
  final String userName;
  final String email;
  final String fullName;
  final String role; // Admin, Staff, Customer
  final String? token;

  AppUser({
    required this.id,
    required this.userName,
    required this.email,
    required this.fullName,
    required this.role,
    this.token,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] ?? json['userId'] ?? json['UserId'] ?? '1').toString(),
      userName: (json['userName'] ?? json['username'] ?? json['Username'] ?? '').toString(),
      email: (json['email'] ?? json['Email'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['FullName'] ?? json['userName'] ?? '').toString(),
      role: (json['role'] ?? json['Role'] ?? 'Customer').toString(),
      token: json['token'] ?? json['Token'],
    );
  }
}
