import 'package:flutter/material.dart';

import '../data/sample_claims.dart';
import '../models/claim_model.dart';
import '../models/notification_model.dart';
import '../services/firebase_item_service.dart';
import '../services/storage_service.dart';
import 'qr_verification_screen.dart';
import 'item_chat_screen.dart';

class ManageClaimsScreen extends StatefulWidget {
  final String? itemId;

  const ManageClaimsScreen({super.key, this.itemId});

  @override
  State<ManageClaimsScreen> createState() => _ManageClaimsScreenState();
}

class _ManageClaimsScreenState extends State<ManageClaimsScreen> {
  List<ClaimModel> get visibleClaims => sampleClaims
      .where((claim) => widget.itemId == null || claim.item.id == widget.itemId)
      .toList();

  Future<void> updateClaimStatus(ClaimModel claim, String status) async {
    final affectedClaims = <ClaimModel>{claim};
    final previousStatuses = <ClaimModel, String>{
      for (final existing in sampleClaims) existing: existing.status,
    };
    final previousItemStatus = claim.item.status;
    setState(() {
      claim.status = status;
      if (status == 'Approved') {
        claim.item.status = 'Claimed';
        for (final competingClaim in sampleClaims) {
          if (competingClaim.id != claim.id &&
              competingClaim.item.id == claim.item.id &&
              competingClaim.status == 'Pending') {
            competingClaim.status = 'Rejected';
            affectedClaims.add(competingClaim);
          }
        }
      } else if (status == 'Rejected') {
        final claimsForItem = sampleClaims.where(
          (other) => other.item.id == claim.item.id,
        );
        if (claimsForItem.any((other) => other.status == 'Approved')) {
          claim.item.status = 'Claimed';
        } else {
          claim.item.status = claim.item.type == 'found'
              ? 'Available'
              : 'Missing';
        }
      }
    });

    final updated = await FirebaseItemService.applyClaimDecision(
      claims: affectedClaims,
      item: claim.item,
      approvedClaimantUid: status == 'Approved' ? claim.claimantUid : null,
    );
    if (!updated) {
      for (final entry in previousStatuses.entries) {
        entry.key.status = entry.value;
      }
      claim.item.status = previousItemStatus;
      if (mounted) setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FirebaseItemService.lastFirestoreError ??
                  'Claim status could not be updated.',
            ),
          ),
        );
      }
      return;
    }
    await StorageService.saveAll();
    await FirebaseItemService.uploadNotification(
      NotificationModel(
        id: 'claim-status-${claim.id}-$status',
        recipientUid: claim.claimantUid,
        title: 'Claim $status',
        body: 'Your claim for ${claim.item.name} was ${status.toLowerCase()}.',
        type: 'claim_status',
        itemId: claim.item.id,
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    for (final competingClaim in affectedClaims.where(
      (other) => other.id != claim.id && other.status == 'Rejected',
    )) {
      await FirebaseItemService.uploadNotification(
        NotificationModel(
          id: 'claim-status-${competingClaim.id}-Rejected',
          recipientUid: competingClaim.claimantUid,
          title: 'Claim Rejected',
          body: 'Another claim for ${competingClaim.item.name} was verified.',
          type: 'claim_status',
          itemId: competingClaim.item.id,
          createdAtMillis: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text('Claim has been $status'),
      ),
    );
  }

  Color getStatusColor(String status) {
    if (status == 'Approved') {
      return const Color(0xFF4DB6AC);
    } else if (status == 'Rejected') {
      return const Color(0xFFEF5350);
    } else {
      return const Color(0xFFFFB74D);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.itemId == null ? 'Manage Claims' : 'Review Claims'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: visibleClaims.isEmpty
          ? const Center(
              child: Text(
                'No claim requests yet.\nSubmit a claim from Found Items first.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: visibleClaims.length,
              itemBuilder: (context, index) {
                final claim = visibleClaims[index];
                final statusColor = getStatusColor(claim.status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(
                              0xFF6C63FF,
                            ).withValues(alpha: 0.1),
                            child: Text(
                              claim.item.imageEmoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  claim.item.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Claimed by ${claim.claimantName}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              claim.status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      InfoText(label: 'Student ID', value: claim.studentId),

                      InfoText(label: 'Proof', value: claim.proofDescription),

                      const SizedBox(height: 14),

                      if (claim.status == 'Pending')
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    updateClaimStatus(claim, 'Approved'),
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4DB6AC),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    updateClaimStatus(claim, 'Rejected'),
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Reject'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF5350),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (claim.status == 'Approved') ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QrVerificationScreen(
                                    claim: claim,
                                    canCompleteCollection: true,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code_2_rounded),
                            label: const Text('Show Collection QR'),
                          ),
                        ),
                      ],
                      if (claim.status == 'Pending' ||
                          claim.status == 'Approved') ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ItemChatScreen(
                                  item: claim.item,
                                  conversationId: claim.id,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.chat_outlined),
                            label: const Text('Chat with claimant'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class InfoText extends StatelessWidget {
  final String label;
  final String value;

  const InfoText({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.3),
          ),
        ],
      ),
    );
  }
}
