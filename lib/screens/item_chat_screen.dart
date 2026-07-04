import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/chat_message_model.dart';
import '../models/item_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_item_service.dart';
import '../utils/item_form_helper.dart';

class ItemChatScreen extends StatefulWidget {
  final ItemModel item;
  final String conversationId;

  const ItemChatScreen({
    super.key,
    required this.item,
    required this.conversationId,
  });

  @override
  State<ItemChatScreen> createState() => _ItemChatScreenState();
}

class _ItemChatScreenState extends State<ItemChatScreen> {
  final messageController = TextEditingController();
  bool sending = false;

  Future<void> send() async {
    final user = AuthService.currentUser;
    final text = messageController.text.trim();
    final uid = FirebaseItemService.currentUid;
    if (user == null || uid == null || text.isEmpty || sending) return;

    setState(() => sending = true);
    final now = DateTime.now();
    final message = ChatMessageModel(
      id: ItemFormHelper.createId(),
      itemId: widget.conversationId,
      sender: user.name,
      senderUid: uid,
      senderEmail: user.email,
      message: text,
      createdAt: ItemFormHelper.formattedToday(),
      createdAtMillis: now.millisecondsSinceEpoch,
    );
    final saved = await FirebaseItemService.uploadChatMessage(message);
    if (!mounted) return;
    setState(() {
      sending = false;
      if (saved) messageController.clear();
    });
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message could not be sent.')),
      );
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseItemService.currentUid;
    return Scaffold(
      appBar: AppBar(title: Text('Chat: ${widget.item.name}')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('itemChats')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('createdAtMillis')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Chat is unavailable.'));
                }
                final messages =
                    snapshot.data?.docs
                        .map((doc) => ChatMessageModel.fromJson(doc.data()))
                        .toList() ??
                    <ChatMessageModel>[];
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final mine = message.senderUid == currentUid;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Card(
                        color: mine
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.sender,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(message.message),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Message'),
                      onSubmitted: (_) => send(),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: sending ? null : send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
