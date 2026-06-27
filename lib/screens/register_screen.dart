import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_item_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final contactController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  InputDecoration inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF2F6F73), width: 1.4),
      ),
    );
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final contact = contactController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || contact.isEmpty || password.isEmpty) {
      showMessage('Please fill in all fields');
      return;
    }

    if (!AuthService.isValidInstitutionEmail(email) ||
        AuthService.isAdminEmail(email)) {
      showMessage('Use a valid student, lecturer, or staff campus email');
      return;
    }

    if (!AuthService.isValidPassword(password)) {
      showMessage('Password must be at least 6 characters');
      return;
    }

    final user = UserModel(
      name: name,
      email: email,
      role: AuthService.roleForEmail(email),
      contactNumber: contact,
      password: password,
    );

    setState(() {
      isLoading = true;
    });

    var cloudSaved = false;
    try {
      cloudSaved = await AuthService.registerUser(user);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      showMessage(error.toString().replaceFirst('Bad state: ', ''));
      return;
    }

    if (!mounted) return;
    final message = cloudSaved
        ? 'Account created and saved to cloud.'
        : 'Account created locally. Cloud sync failed: ${FirebaseItemService.lastFirestoreError ?? 'check Firebase setup'}';
    showMessage(message);
    Navigator.pop(context, user);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    contactController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF2F6F73),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join LostLink',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Register with a campus email. Your role is assigned from your email domain.',
                    style: TextStyle(color: Colors.white, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: inputDecoration(
                'Name',
                'Example: Tan Mei Ling',
                Icons.person_rounded,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: inputDecoration(
                'Campus Email',
                'name@student.campus.edu.my',
                Icons.email_rounded,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: contactController,
              keyboardType: TextInputType.phone,
              decoration: inputDecoration(
                'Contact Number',
                'Example: 012-3456789',
                Icons.phone_rounded,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: hidePassword,
              decoration:
                  inputDecoration(
                    'Password',
                    'At least 6 characters',
                    Icons.lock_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),
                  ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F6F73),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  isLoading ? 'Creating...' : 'Create Account',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
