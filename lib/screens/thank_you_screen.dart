import 'package:flutter/material.dart';

import '../data/app_records.dart';
import '../models/item_model.dart';
import '../models/thank_you_model.dart';
import '../services/firebase_item_service.dart';
import '../services/storage_service.dart';
import '../utils/item_form_helper.dart';

class ThankYouScreen extends StatefulWidget {
  final ItemModel item;

  const ThankYouScreen({super.key, required this.item});

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> {
  final fromController = TextEditingController();
  final messageController = TextEditingController();

  Future<void> submit() async {
    if (fromController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final message = ThankYouModel(
      id: ItemFormHelper.createId(),
      itemId: widget.item.id,
      itemName: widget.item.name,
      fromName: fromController.text.trim(),
      toName: widget.item.reporterName.isEmpty
          ? 'Finder'
          : widget.item.reporterName,
      message: messageController.text.trim(),
      createdAt: ItemFormHelper.formattedToday(),
    );

    thankYouMessages.add(message);
    await StorageService.saveThankYouMessages();
    await FirebaseItemService.uploadThankYouMessage(message);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Thank-you message sent.')));
  }

  @override
  void dispose() {
    fromController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Thank You')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('For ${widget.item.name}'),
          const SizedBox(height: 12),
          TextField(
            controller: fromController,
            decoration: const InputDecoration(labelText: 'Your name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: messageController,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Message'),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: submit,
            icon: const Icon(Icons.favorite_rounded),
            label: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
