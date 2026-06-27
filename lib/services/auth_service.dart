import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'firebase_item_service.dart';

class AuthService {
  static const String allowedStudentDomain = '@student.campus.edu.my';
  static const String allowedStaffDomain = '@staff.campus.edu.my';
  static const String allowedLecturerDomain = '@lecturer.campus.edu.my';
  static const String adminEmail = 'admin@campus.edu.my';
  static const String _usersKey = 'lost_link_users';

  static bool isValidInstitutionEmail(String email) {
    final normalized = email.toLowerCase().trim();
    return normalized.endsWith(allowedStudentDomain) ||
        normalized.endsWith(allowedStaffDomain) ||
        normalized.endsWith(allowedLecturerDomain) ||
        normalized == adminEmail;
  }

  static bool isAdminEmail(String email) {
    return email.toLowerCase().trim() == adminEmail;
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static String roleForEmail(String email) {
    final normalized = email.toLowerCase().trim();
    if (normalized == adminEmail) return 'Admin';
    if (normalized.endsWith(allowedLecturerDomain)) return 'Lecturer';
    if (normalized.endsWith(allowedStaffDomain)) return 'Staff';
    return 'Student';
  }

  static Future<List<UserModel>> loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    if (usersJson == null) return [];

    final decodedUsers = jsonDecode(usersJson) as List<dynamic>;
    return decodedUsers
        .map((user) => UserModel.fromJson(user as Map<String, dynamic>))
        .toList();
  }

  static Future<bool> registerUser(UserModel user) async {
    final users = await loadUsers();
    final email = user.email.toLowerCase().trim();
    if (users.any((existingUser) => existingUser.email == email)) {
      throw StateError('An account already exists for this email');
    }

    users.add(
      UserModel(
        name: user.name.trim(),
        email: email,
        role: user.role,
        contactNumber: user.contactNumber.trim(),
        password: user.password,
      ),
    );

    await _saveUsers(users);
    return FirebaseItemService.uploadUser(user);
  }

  static Future<UserModel?> authenticate({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.toLowerCase().trim();
    final users = await loadUsers();

    for (final user in users) {
      if (user.email == normalizedEmail && user.password == password) {
        return user;
      }
    }

    if (isAdminEmail(normalizedEmail) && isValidPassword(password)) {
      return UserModel(
        name: 'Admin',
        email: normalizedEmail,
        role: 'Admin',
        contactNumber: '',
        password: password,
      );
    }

    return null;
  }

  static Future<void> _saveUsers(List<UserModel> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _usersKey,
      jsonEncode(users.map((user) => user.toJson()).toList()),
    );
  }
}
