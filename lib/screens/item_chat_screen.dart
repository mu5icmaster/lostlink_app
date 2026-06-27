import 'package:flutter/material.dart';

import '../data/app_records.dart';
import '../models/chat_message_model.dart';
import '../models/item_model.dart';
import '../services/firebase_item_service.dart';
import '../services/storage_service.dart';
import '../utils/item_form_helper.dart';

class ItemChatScreen extends StatefulWidget {
  final ItemModel item;

  const ItemChatScreen({super.key, required this.item});

  @override
  State<ItemChatScreen> createState() => _ItemChatScreenState();
}

class _ItemChatScreenState extends State<ItemChatScreen> {
  final senderController = TextEditingController();
  final messageController = TextEditingController();

  List<ChatMessageModel> get messages {
    return chatMessages
        .where((message) => message.itemId == widget.item.id)
        .toList();
  }

  Future<void> send() async {
    if (senderController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      return;
    }

    final message = ChatMessageModel(
      id: ItemFormHelper.createId(),
      itemId: widget.item.id,
      sender: senderController.text.trim(),
      message: messageController.text.trim(),
      createdAt: ItemFormHelper.formattedToday(),
    );

    setState(() {
      chatMessages.add(message);
      messageController.clear();
    });
    await StorageService.saveChatMessages();
    await FirebaseItemService.uploadChatMessage(message);
  }

  @override
  void dispose() {
    senderController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat: ${widget.item.name}')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Messages are intended for admin-monitored coordination after a claim is being handled.',
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return ListTile(
                  title: Text(message.sender),
                  subtitle: Text(message.message),
                  trailing: Text(message.createdAt),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: senderController,
                  decoration: const InputDecoration(labelText: 'Your name'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        decoration: const InputDecoration(labelText: 'Message'),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: send,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
