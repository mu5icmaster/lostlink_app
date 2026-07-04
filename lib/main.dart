import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'services/app_settings_service.dart';
import 'services/firebase_item_service.dart';
import 'services/storage_service.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettingsService.load();
  await FirebaseItemService.initialize();
  if (FirebaseItemService.isAvailable) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  }
  await StorageService.loadData();
  runApp(const LostLinkApp());
}

class LostLinkApp extends StatelessWidget {
  const LostLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: AppSettingsService.settings,
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'LostLink',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF7F7FB),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2F6F73),
            ),
            fontFamily: 'Arial',
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF7F7FB),
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF4F4FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF101414),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4DB6AC),
              brightness: Brightness.dark,
            ),
            fontFamily: 'Arial',
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF101414),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF263030),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}
