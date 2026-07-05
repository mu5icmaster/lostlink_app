import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/claim_model.dart';
import '../models/notification_model.dart';
import '../services/firebase_item_service.dart';
import '../services/storage_service.dart';

class QrVerificationScreen extends StatelessWidget {
  final ClaimModel claim;
  final bool canCompleteCollection;

  const QrVerificationScreen({
    super.key,
    required this.claim,
    this.canCompleteCollection = false,
  });

  String get verificationCode => 'LOSTLINK-${claim.id}-${claim.item.id}';

  Future<void> completeCollection(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm item handover?'),
        content: Text(
          'Confirm that ${claim.claimantName} collected ${claim.item.name}. This closes the report.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm handover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final previousItemStatus = claim.item.status;
    final previousClaimStatus = claim.status;
    claim.item.status = 'Returned';
    claim.status = 'Collected';
    final updated = await FirebaseItemService.applyClaimDecision(
      claims: [claim],
      item: claim.item,
    );
    if (!updated) {
      claim.item.status = previousItemStatus;
      claim.status = previousClaimStatus;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            FirebaseItemService.lastFirestoreError ??
                'Handover could not be completed.',
          ),
        ),
      );
      return;
    }
    await StorageService.saveAll();
    await FirebaseItemService.uploadNotification(
      NotificationModel(
        id: 'collection-${claim.id}',
        recipientUid: claim.claimantUid,
        title: 'Collection completed',
        body: '${claim.item.name} has been marked as returned.',
        type: 'claim_status',
        itemId: claim.item.id,
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (!context.mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Claim QR Verification')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(data: verificationCode, size: 240),
              const SizedBox(height: 18),
              Text(
                claim.item.name,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SelectableText(
                verificationCode,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                canCompleteCollection
                    ? 'Compare this pass with the claimant’s pass before handing over the item.'
                    : 'Show this pass to the reporter or campus staff during collection.',
                textAlign: TextAlign.center,
              ),
              if (canCompleteCollection) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => completeCollection(context),
                  icon: const Icon(Icons.verified_rounded),
                  label: const Text('Confirm handover'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
