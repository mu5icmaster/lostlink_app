import 'package:flutter/material.dart';

import '../data/sample_items.dart';
import '../models/user_model.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';

class MyReportsScreen extends StatelessWidget {
  final UserModel currentUser;

  const MyReportsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final myReports = sampleItems
        .where((item) => item.reporterEmail == currentUser.email)
        .toList()
        .reversed
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Reports'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: myReports.isEmpty
          ? const Center(
              child: Text(
                'No reports submitted yet.',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: myReports.length,
              itemBuilder: (context, index) {
                final item = myReports[index];
                return ItemCard(
                  item: item,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemDetailScreen(item: item),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
