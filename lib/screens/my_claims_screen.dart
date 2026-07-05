import 'package:flutter/material.dart';

import '../data/sample_claims.dart';
import '../models/claim_model.dart';
import '../models/user_model.dart';
import '../services/firebase_item_service.dart';
import '../services/storage_service.dart';
import 'item_chat_screen.dart';
import 'item_detail_screen.dart';
import 'qr_verification_screen.dart';

class MyClaimsScreen extends StatefulWidget {
  final UserModel currentUser;

  const MyClaimsScreen({super.key, required this.currentUser});

  @override
  State<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends State<MyClaimsScreen> {
  List<ClaimModel> get claims =>
      sampleClaims
          .where((claim) => claim.claimantEmail == widget.currentUser.email)
          .toList()
        ..sort(
          (a, b) => (b.createdAtMillis ?? 0).compareTo(a.createdAtMillis ?? 0),
        );

  Future<void> cancelClaim(ClaimModel claim) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel claim?'),
        content: Text('Withdraw your claim for ${claim.item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep claim'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final previousStatus = claim.status;
    setState(() => claim.status = 'Withdrawn');
    final uploaded = await FirebaseItemService.uploadClaim(claim);
    if (!uploaded) {
      if (mounted) setState(() => claim.status = previousStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FirebaseItemService.lastFirestoreError ??
                  'Claim could not be withdrawn.',
            ),
          ),
        );
      }
      return;
    }
    await StorageService.saveClaims();
  }

  @override
  Widget build(BuildContext context) {
    final myClaims = claims;
    return Scaffold(
      appBar: AppBar(title: const Text('My Claims'), centerTitle: true),
      body: myClaims.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'You have not submitted any claims yet.\nBrowse Found Items to start.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: myClaims.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final claim = myClaims[index];
                final approved = claim.status == 'Approved';
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                claim.item.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Chip(label: Text(claim.status)),
                          ],
                        ),
                        Text(
                          approved
                              ? 'Approved. Use the collection pass below when collecting the item.'
                              : claim.status == 'Pending'
                              ? 'Your ownership evidence is awaiting review.'
                              : 'This claim is ${claim.status.toLowerCase()}.',
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ItemDetailScreen(item: claim.item),
                                ),
                              ),
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('View item'),
                            ),
                            if (claim.status == 'Pending' || approved)
                              OutlinedButton.icon(
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
                                label: const Text('Chat'),
                              ),
                            if (approved)
                              FilledButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QrVerificationScreen(
                                      claim: claim,
                                      canCompleteCollection: false,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.qr_code_2_rounded),
                                label: const Text('Collection pass'),
                              ),
                            if (claim.status == 'Pending')
                              TextButton(
                                onPressed: () => cancelClaim(claim),
                                child: const Text('Withdraw claim'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
