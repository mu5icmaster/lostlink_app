import 'package:flutter/material.dart';

import '../data/sample_claims.dart';
import '../models/claim_model.dart';
import '../models/item_model.dart';
import '../models/notification_model.dart';
import '../services/firebase_item_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../data/sample_items.dart';

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
  final formKey = GlobalKey<FormState>();
  String? linkedLostItemId;
  bool isSubmitting = false;

  List<ItemModel> get myOpenLostReports {
    final user = AuthService.currentUser;
    if (user == null) return const [];
    return sampleItems
        .where(
          (item) =>
              item.type == 'lost' &&
              item.reporterEmail == user.email &&
              item.status == 'Missing',
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    nameController.text = user?.name ?? '';
    contactController.text = user?.contactNumber ?? '';
    final reports = myOpenLostReports;
    if (reports.length == 1) linkedLostItemId = reports.single.id;
  }

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
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again before claiming.')),
      );
      return;
    }

    if (widget.item.type != 'found' || widget.item.status != 'Available') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This item is no longer available.')),
      );
      return;
    }
    if (widget.item.reporterUid == FirebaseItemService.currentUid ||
        widget.item.reporterEmail == currentUser.email) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot claim your own report.')),
      );
      return;
    }

    final alreadyClaimed = sampleClaims.any(
      (claim) =>
          claim.item.id == widget.item.id &&
          claim.claimantEmail == currentUser.email &&
          (claim.status == 'Pending' || claim.status == 'Approved'),
    );
    if (alreadyClaimed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already have an active claim.')),
      );
      return;
    }
    if (!(formKey.currentState?.validate() ?? false) || isSubmitting) return;
    setState(() => isSubmitting = true);

    final newClaim = ClaimModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      item: widget.item,
      claimantName: nameController.text.trim(),
      claimantEmail: currentUser.email,
      claimantUid: FirebaseItemService.currentUid ?? '',
      itemOwnerUid: widget.item.reporterUid,
      studentId: studentIdController.text.trim(),
      contactInfo: contactController.text.trim(),
      proofDescription: proofController.text.trim(),
      linkedLostItemId: linkedLostItemId,
      status: 'Pending',
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
    );

    sampleClaims.add(newClaim);
    await StorageService.saveAll();
    final uploaded = await FirebaseItemService.uploadClaim(newClaim);
    if (!uploaded) {
      sampleClaims.removeWhere((claim) => claim.id == newClaim.id);
      await StorageService.saveClaims();
      if (!mounted) return;
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The claim could not be submitted. Check your connection and try again.',
          ),
        ),
      );
      return;
    }
    await FirebaseItemService.uploadNotification(
      NotificationModel(
        id: 'claim-${newClaim.id}',
        recipientUid: widget.item.reporterUid,
        title: 'New claim request',
        body: '${currentUser.name} submitted a claim for ${widget.item.name}.',
        type: 'claim_request',
        itemId: widget.item.id,
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    if (!mounted) return;
    setState(() => isSubmitting = false);
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
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      validator: requiredValue,
                      decoration: customInputDecoration(
                        'Full Name',
                        'Example: Tan Mei Ling',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: studentIdController,
                      textInputAction: TextInputAction.next,
                      validator: requiredValue,
                      decoration: customInputDecoration(
                        'Student or Staff ID',
                        'Example: I22012345',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: contactController,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      textInputAction: TextInputAction.next,
                      validator: requiredValue,
                      decoration: customInputDecoration(
                        'Contact Details',
                        'Phone or email for claim updates',
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (myOpenLostReports.isNotEmpty) ...[
                      DropdownButtonFormField<String?>(
                        initialValue: linkedLostItemId,
                        decoration: customInputDecoration(
                          'Link your lost report (optional)',
                          'Provides supporting report details',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('No linked report'),
                          ),
                          ...myOpenLostReports.map(
                            (item) => DropdownMenuItem<String?>(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => linkedLostItemId = value),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: proofController,
                      maxLines: 5,
                      validator: requiredValue,
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
                        onPressed: isSubmitting ? null : submitClaim,
                        icon: const Icon(Icons.send_rounded),
                        label: Text(
                          isSubmitting
                              ? 'Submitting...'
                              : 'Submit Claim Request',
                        ),
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
            ),
          ],
        ),
      ),
    );
  }

  String? requiredValue(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;
}
