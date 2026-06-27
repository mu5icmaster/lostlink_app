class UserModel {
  final String name;
  final String email;
  final String role;
  final String contactNumber;
  final String password;
  final String? profileImageUrl;
  final String? profileImagePath;

  UserModel({
    required this.name,
    required this.email,
    required this.role,
    required this.contactNumber,
    required this.password,
    this.profileImageUrl,
    this.profileImagePath,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      contactNumber: json['contactNumber'] as String? ?? '',
      password: json['password'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      profileImagePath: json['profileImagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'contactNumber': contactNumber,
      'password': password,
      'profileImageUrl': profileImageUrl,
      'profileImagePath': profileImagePath,
    };
  }
}
