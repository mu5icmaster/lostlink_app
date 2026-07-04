import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/app_settings_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_item_service.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool accountActionRunning = false;

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> verifyEmail() async {
    setState(() => accountActionRunning = true);
    try {
      await FirebaseItemService.sendEmailVerification();
      if (mounted) message('Verification email sent.');
    } on FirebaseAuthException catch (error) {
      if (mounted) message(error.message ?? 'Could not verify email.');
    } finally {
      if (mounted) setState(() => accountActionRunning = false);
    }
  }

  Future<void> resetPassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    setState(() => accountActionRunning = true);
    try {
      await FirebaseItemService.sendPasswordReset(email);
      if (mounted) message('Password reset email sent.');
    } finally {
      if (mounted) setState(() => accountActionRunning = false);
    }
  }

  Future<void> deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your Firebase account and profile. You may need to sign in again first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => accountActionRunning = true);
    try {
      await FirebaseItemService.deleteCurrentAccount();
      await StorageService.clearPrivateSessionData();
      AuthService.currentUser = null;
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        message(
          error.code == 'requires-recent-login'
              ? 'Sign out, sign in again, then retry account deletion.'
              : error.message ?? 'Account deletion failed.',
        );
      }
    } finally {
      if (mounted) setState(() => accountActionRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: AppSettingsService.settings,
      builder: (context, settings, _) {
        return Scaffold(
          appBar: AppBar(title: Text(AppSettingsService.text('settings'))),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: SwitchListTile(
                  title: Text(AppSettingsService.text('darkMode')),
                  value: settings.themeMode == ThemeMode.dark,
                  onChanged: (enabled) {
                    AppSettingsService.setThemeMode(
                      enabled ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.mark_email_read_rounded),
                      title: const Text('Verify email'),
                      onTap:
                          accountActionRunning ||
                              FirebaseAuth.instance.currentUser == null
                          ? null
                          : verifyEmail,
                    ),
                    ListTile(
                      leading: const Icon(Icons.password_rounded),
                      title: const Text('Reset password'),
                      onTap:
                          accountActionRunning ||
                              FirebaseAuth.instance.currentUser == null
                          ? null
                          : resetPassword,
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_rounded),
                      title: const Text('Delete account'),
                      textColor: Theme.of(context).colorScheme.error,
                      iconColor: Theme.of(context).colorScheme.error,
                      onTap:
                          accountActionRunning ||
                              FirebaseAuth.instance.currentUser == null
                          ? null
                          : deleteAccount,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppSettingsService.text('language'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: settings.languageCode,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'ms', child: Text('Malay')),
                          DropdownMenuItem(value: 'zh', child: Text('Chinese')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          AppSettingsService.setLanguageCode(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
