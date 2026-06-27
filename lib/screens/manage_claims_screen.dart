import 'package:flutter/material.dart';

import '../data/sample_claims.dart';
import '../models/claim_model.dart';
import '../services/firebase_item_service.dart';
import '../services/storage_service.dart';
import 'qr_verification_screen.dart';

class ManageClaimsScreen extends StatefulWidget {
  const ManageClaimsScreen({super.key});

  @override
  State<ManageClaimsScreen> createState() => _ManageClaimsScreenState();
}

class _ManageClaimsScreenState extends State<ManageClaimsScreen> {
  Future<void> updateClaimStatus(ClaimModel claim, String status) async {
    setState(() {
      claim.status = status;
      if (status == 'Approved') {
        claim.item.status = 'Claimed';
      } else if (status == 'Rejected' && claim.item.type == 'found') {
        claim.item.status = 'Available';
      }
    });

    await StorageService.saveAll();
    await FirebaseItemService.uploadClaim(claim);
    await FirebaseItemService.uploadItem(item: claim.item);

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
        title: const Text('Manage Claims'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: sampleClaims.isEmpty
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
              itemCount: sampleClaims.length,
              itemBuilder: (context, index) {
                final claim = sampleClaims[index];
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
                                  builder: (_) =>
                                      QrVerificationScreen(claim: claim),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code_2_rounded),
                            label: const Text('Show Collection QR'),
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
