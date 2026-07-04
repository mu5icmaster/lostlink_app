import 'package:flutter/material.dart';

import '../data/sample_items.dart';
import '../data/sample_claims.dart';
import '../data/app_records.dart';
import '../models/item_model.dart';
import '../services/firebase_item_service.dart';
import '../services/storage_service.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';

class ManageItemsScreen extends StatefulWidget {
  const ManageItemsScreen({super.key});

  @override
  State<ManageItemsScreen> createState() => _ManageItemsScreenState();
}

class _ManageItemsScreenState extends State<ManageItemsScreen> {
  String selectedType = 'All';
  final List<String> statuses = [
    'Missing',
    'Available',
    'Pending Claim',
    'Claimed',
    'Returned',
    'Withdrawn',
    'Expired',
    'Rejected',
  ];

  List<ItemModel> getFilteredItems() {
    if (selectedType == 'Lost') {
      return sampleItems.where((item) => item.type == 'lost').toList();
    } else if (selectedType == 'Found') {
      return sampleItems.where((item) => item.type == 'found').toList();
    } else {
      return sampleItems;
    }
  }

  Future<void> updateItemStatus(ItemModel item, String status) async {
    setState(() {
      item.status = status;
    });
    await StorageService.saveItems();
    await FirebaseItemService.uploadItem(item: item);
  }

  Future<void> removeItem(ItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove item?'),
          content: Text('This will remove "${item.name}" from item reports.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      sampleItems.removeWhere((existingItem) => existingItem.id == item.id);
      sampleClaims.removeWhere((claim) => claim.item.id == item.id);
      chatMessages.removeWhere((message) => message.itemId == item.id);
      abuseReports.removeWhere((report) => report.itemId == item.id);
      thankYouMessages.removeWhere((message) => message.itemId == item.id);
    });
    await StorageService.saveAll();
    await FirebaseItemService.deleteItem(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = getFilteredItems();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Manage Items'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4DB6AC), Color(0xFF42A5F5)],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item Reports 📦',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'View all lost and found reports submitted by users.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                FilterChipButton(
                  text: 'All',
                  selected: selectedType == 'All',
                  onTap: () {
                    setState(() {
                      selectedType = 'All';
                    });
                  },
                ),
                const SizedBox(width: 10),
                FilterChipButton(
                  text: 'Lost',
                  selected: selectedType == 'Lost',
                  onTap: () {
                    setState(() {
                      selectedType = 'Lost';
                    });
                  },
                ),
                const SizedBox(width: 10),
                FilterChipButton(
                  text: 'Found',
                  selected: selectedType == 'Found',
                  onTap: () {
                    setState(() {
                      selectedType = 'Found';
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 18),

            Expanded(
              child: ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];

                  return Column(
                    children: [
                      ItemCard(
                        item: item,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailScreen(item: item),
                            ),
                          );
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: statuses.contains(item.status)
                                  ? item.status
                                  : null,
                              decoration: InputDecoration(
                                labelText: 'Status',
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: statuses.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                updateItemStatus(item, value);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            onPressed: () => removeItem(item),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterChipButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const FilterChipButton({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
