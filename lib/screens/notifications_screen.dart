import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/sample_items.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/firebase_item_service.dart';
import '../utils/match_helper.dart';
import 'item_detail_screen.dart';
import 'manage_claims_screen.dart';
import 'my_claims_screen.dart';

class NotificationsScreen extends StatelessWidget {
  final UserModel currentUser;

  const NotificationsScreen({super.key, required this.currentUser});

  Future<void> openNotification(
    BuildContext context,
    NotificationModel notification,
  ) async {
    if (!notification.id.startsWith('match-')) {
      await FirebaseItemService.markNotificationRead(notification.id);
    }
    if (!context.mounted) return;
    if (notification.type == 'claim_status') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MyClaimsScreen(currentUser: currentUser),
        ),
      );
      return;
    }
    if (notification.type == 'claim' && notification.itemId != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ManageClaimsScreen(itemId: notification.itemId),
        ),
      );
      return;
    }
    final itemIndex = sampleItems.indexWhere(
      (candidate) => candidate.id == notification.itemId,
    );
    if (itemIndex >= 0 && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ItemDetailScreen(item: sampleItems[itemIndex]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseItemService.currentUid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view notifications.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientUid', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          final notifications =
              snapshot.data?.docs
                  .map((doc) => NotificationModel.fromJson(doc.data()))
                  .toList() ??
              <NotificationModel>[];
          notifications.sort(
            (a, b) => b.createdAtMillis.compareTo(a.createdAtMillis),
          );

          final matchAlerts = <NotificationModel>[];
          for (final item in sampleItems.where(
            (item) =>
                item.reporterEmail == currentUser.email && item.type == 'lost',
          )) {
            final matches = MatchHelper.findPossibleMatches(
              lostItem: item,
              allItems: sampleItems,
            );
            if (matches.isNotEmpty) {
              matchAlerts.add(
                NotificationModel(
                  id: 'match-${item.id}',
                  recipientUid: uid,
                  title: 'Possible match',
                  body:
                      '${matches.length} possible match(es) found for ${item.name}.',
                  type: 'match',
                  itemId: item.id,
                  createdAtMillis: item.createdAtMillis ?? 0,
                ),
              );
            }
          }
          final all = [...notifications, ...matchAlerts];
          if (all.isEmpty) return const Center(child: Text('No updates yet.'));

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: all.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notification = all[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    notification.isRead
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_rounded,
                  ),
                  title: Text(notification.title),
                  subtitle: Text(notification.body),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => openNotification(context, notification),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
