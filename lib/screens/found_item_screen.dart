import 'package:flutter/material.dart';

import '../data/sample_items.dart';
import '../models/item_model.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';

class FoundItemsScreen extends StatefulWidget {
  const FoundItemsScreen({super.key});

  @override
  State<FoundItemsScreen> createState() => _FoundItemsScreenState();
}

class _FoundItemsScreenState extends State<FoundItemsScreen> {
  String searchText = '';
  String selectedCategory = 'All';

  List<String> get categories {
    return [
      'All',
      ...sampleItems.map((item) => item.category).toSet().toList()..sort(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final foundItems = sampleItems.where((item) {
      final query = searchText.toLowerCase();
      final isFound =
          item.type == 'found' &&
          (item.status == 'Available' || item.status == 'Claimed');
      final matchesCategory =
          selectedCategory == 'All' || item.category == selectedCategory;
      final matchesSearch =
          item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);

      return isFound && matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Found Items'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const HeaderPanel(
              title: 'Found Items',
              subtitle: 'Check items that were found around campus.',
              colors: [Color(0xFF4DB6AC), Color(0xFF42A5F5)],
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search found items...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ChoiceChip(
                    label: Text(category),
                    selected: selectedCategory == category,
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: foundItems.isEmpty
                  ? const Center(
                      child: Text(
                        'No found items match your filters.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: foundItems.length,
                      itemBuilder: (context, index) {
                        final ItemModel item = foundItems[index];

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
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color> colors;

  const HeaderPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(colors: colors),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
