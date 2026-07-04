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
  static UserModel? currentUser;

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

  static Future<bool> registerUser(
    UserModel user, {
    required String password,
  }) async {
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
      ),
    );

    final cloudSaved = await FirebaseItemService.registerUser(
      user,
      password: password,
    );
    if (!cloudSaved) {
      throw StateError(
        FirebaseItemService.lastAuthError ??
            FirebaseItemService.lastFirestoreError ??
            'Firebase registration failed',
      );
    }
    await _saveUsers(users);
    return true;
  }

  static Future<UserModel?> authenticate({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.toLowerCase().trim();

    final signedIn = await FirebaseItemService.signInUser(
      email: normalizedEmail,
      password: password,
    );
    if (!signedIn) return null;

    return _resolveProfile(normalizedEmail);
  }

  static Future<UserModel?> restoreSession() async {
    final email = FirebaseItemService.currentEmail;
    if (email == null || !isValidInstitutionEmail(email)) return null;
    return _resolveProfile(email.toLowerCase().trim());
  }

  static Future<UserModel> _resolveProfile(String normalizedEmail) async {
    final users = await loadUsers();
    for (final user in users) {
      if (user.email == normalizedEmail) {
        currentUser = user;
        return user;
      }
    }

    // SharedPreferences belongs to one device. On a new device, restore the
    // profile from Firestore after Firebase Authentication verifies the login.
    // A minimal derived profile keeps a valid account usable if its older
    // registration succeeded in Auth but failed to sync its Firestore profile.
    final cloudUser = await FirebaseItemService.loadUserProfile(
      normalizedEmail,
    );
    if (cloudUser != null) {
      await FirebaseItemService.uploadUserProfile(cloudUser);
    }
    final user =
        cloudUser ??
        UserModel(
          name: normalizedEmail.split('@').first,
          email: normalizedEmail,
          role: roleForEmail(normalizedEmail),
          contactNumber: '',
        );
    users.add(user);
    await _saveUsers(users);
    currentUser = user;
    return user;
  }

  static Future<void> _saveUsers(List<UserModel> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _usersKey,
      jsonEncode(users.map((user) => user.toJson()).toList()),
    );
  }
}
