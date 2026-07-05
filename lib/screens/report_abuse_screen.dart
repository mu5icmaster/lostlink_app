import 'package:flutter/material.dart';

import '../data/app_records.dart';
import '../models/abuse_report_model.dart';
import '../models/item_model.dart';
import '../services/firebase_item_service.dart';
import '../services/storage_service.dart';
import '../utils/item_form_helper.dart';

class ReportAbuseScreen extends StatefulWidget {
  final ItemModel item;

  const ReportAbuseScreen({super.key, required this.item});

  @override
  State<ReportAbuseScreen> createState() => _ReportAbuseScreenState();
}

class _ReportAbuseScreenState extends State<ReportAbuseScreen> {
  final detailsController = TextEditingController();
  final reporterController = TextEditingController();
  String reason = 'Inappropriate post';

  Future<void> submit() async {
    if (detailsController.text.trim().isEmpty ||
        reporterController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add details and your email')),
      );
      return;
    }

    final report = AbuseReportModel(
      id: ItemFormHelper.createId(),
      itemId: widget.item.id,
      itemName: widget.item.name,
      reporterEmail: reporterController.text.trim(),
      reporterUid: FirebaseItemService.currentUid ?? '',
      reason: reason,
      details: detailsController.text.trim(),
      createdAt: ItemFormHelper.formattedToday(),
    );

    final uploaded = await FirebaseItemService.uploadAbuseReport(report);
    if (!uploaded) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            FirebaseItemService.lastFirestoreError ??
                'Report could not be submitted.',
          ),
        ),
      );
      return;
    }
    abuseReports.add(report);
    await StorageService.saveAbuseReports();

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted for admin review.')),
    );
  }

  @override
  void dispose() {
    detailsController.dispose();
    reporterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(widget.item.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: reason,
            decoration: const InputDecoration(labelText: 'Reason'),
            items: const [
              DropdownMenuItem(
                value: 'Inappropriate post',
                child: Text('Inappropriate post'),
              ),
              DropdownMenuItem(
                value: 'False information',
                child: Text('False information'),
              ),
              DropdownMenuItem(
                value: 'Suspicious claim',
                child: Text('Suspicious claim'),
              ),
            ],
            onChanged: (value) => setState(() => reason = value!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reporterController,
            decoration: const InputDecoration(labelText: 'Your email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: detailsController,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Details'),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: submit,
            icon: const Icon(Icons.flag_rounded),
            label: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }
}
