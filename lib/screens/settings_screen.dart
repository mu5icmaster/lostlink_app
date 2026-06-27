import 'package:flutter/material.dart';

import '../services/app_settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
