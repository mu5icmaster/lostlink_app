class UserModel {
  final String name;
  final String email;
  final String role;
  final String contactNumber;
  final String? profileImageUrl;
  final String? profileImagePath;

  UserModel({
    required this.name,
    required this.email,
    required this.role,
    required this.contactNumber,
    this.profileImageUrl,
    this.profileImagePath,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      contactNumber: json['contactNumber'] as String? ?? '',
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
      'profileImageUrl': profileImageUrl,
      'profileImagePath': profileImagePath,
    };
  }
}
