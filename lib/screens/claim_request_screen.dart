import 'package:flutter/material.dart';

import '../data/sample_claims.dart';
import '../models/claim_model.dart';
import '../models/item_model.dart';
import '../services/firebase_item_service.dart';
import '../services/storage_service.dart';

class ClaimRequestScreen extends StatefulWidget {
  final ItemModel item;

  const ClaimRequestScreen({super.key, required this.item});

  @override
  State<ClaimRequestScreen> createState() => _ClaimRequestScreenState();
}

class _ClaimRequestScreenState extends State<ClaimRequestScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController studentIdController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController proofController = TextEditingController();

  InputDecoration customInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF2F6F73), width: 1.4),
      ),
    );
  }

  Future<void> submitClaim() async {
    if (nameController.text.trim().isEmpty ||
        studentIdController.text.trim().isEmpty ||
        contactController.text.trim().isEmpty ||
        proofController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Text('Please fill in all fields'),
        ),
      );
      return;
    }

    final newClaim = ClaimModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      item: widget.item,
      claimantName: nameController.text.trim(),
      studentId: studentIdController.text.trim(),
      contactInfo: contactController.text.trim(),
      proofDescription: proofController.text.trim(),
      status: 'Pending',
    );

    widget.item.status = 'Pending Claim';
    sampleClaims.add(newClaim);
    await StorageService.saveAll();
    await FirebaseItemService.uploadClaim(newClaim);
    await FirebaseItemService.uploadItem(item: widget.item);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Text('Claim request submitted successfully.'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    nameController.dispose();
    studentIdController.dispose();
    contactController.dispose();
    proofController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF2F6F73);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Claim Request'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2F6F73), Color(0xFF6C63FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Claim this item',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You are requesting to claim: ${widget.item.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: customInputDecoration(
                      'Full Name',
                      'Example: Tan Mei Ling',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: studentIdController,
                    decoration: customInputDecoration(
                      'Student or Staff ID',
                      'Example: I22012345',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: contactController,
                    keyboardType: TextInputType.phone,
                    decoration: customInputDecoration(
                      'Contact Details',
                      'Phone or email for claim updates',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: proofController,
                    maxLines: 5,
                    decoration: customInputDecoration(
                      'Proof of Ownership',
                      'Describe special details only the owner would know',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: submitClaim,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Submit Claim Request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
