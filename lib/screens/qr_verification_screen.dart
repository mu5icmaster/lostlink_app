import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/claim_model.dart';

class QrVerificationScreen extends StatelessWidget {
  final ClaimModel claim;

  const QrVerificationScreen({super.key, required this.claim});

  String get verificationCode => 'LOSTLINK-${claim.id}-${claim.item.id}';

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
              const Text(
                'Show this code during collection. Admin can match it with the approved claim.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
