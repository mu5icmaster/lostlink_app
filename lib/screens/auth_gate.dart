import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<UserModel?> _restore() async {
    final user = await AuthService.restoreSession();
    if (user != null) {
      await StorageService.syncFromCloud();
      await NotificationService.initializeForCurrentUser();
    }
    return user;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (authSnapshot.data == null) return const LoginScreen();

        return FutureBuilder<UserModel?>(
          future: _restore(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final user = profileSnapshot.data;
            return user == null
                ? const LoginScreen()
                : HomeScreen(currentUser: user);
          },
        );
      },
    );
  }
}
