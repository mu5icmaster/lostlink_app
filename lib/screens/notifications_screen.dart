import 'package:flutter/material.dart';

import '../data/sample_claims.dart';
import '../data/sample_items.dart';
import '../models/user_model.dart';
import '../utils/match_helper.dart';

class NotificationsScreen extends StatelessWidget {
  final UserModel currentUser;

  const NotificationsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final alerts = <String>[];

    for (final item in sampleItems) {
      if (item.reporterEmail != currentUser.email) continue;

      if (item.type == 'lost') {
        final matches = MatchHelper.findPossibleMatches(
          lostItem: item,
          allItems: sampleItems,
        );
        if (matches.isNotEmpty) {
          alerts.add(
            '${matches.length} possible match(es) found for ${item.name}.',
          );
        }
      }

      final relatedClaims = sampleClaims.where(
        (claim) => claim.item.id == item.id,
      );
      for (final claim in relatedClaims) {
        alerts.add(
          '${claim.claimantName} claim for ${item.name}: ${claim.status}.',
        );
      }

      if (item.status == 'Expired') {
        alerts.add('${item.name} has expired after 90 days.');
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: alerts.isEmpty
          ? const Center(child: Text('No updates yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: alerts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active_rounded),
                    title: Text(alerts[index]),
                  ),
                );
              },
            ),
    );
  }
}
