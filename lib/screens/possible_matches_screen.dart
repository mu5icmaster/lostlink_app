import 'package:flutter/material.dart';

import '../data/sample_items.dart';
import '../models/item_model.dart';
import '../utils/match_helper.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';

class PossibleMatchesScreen extends StatelessWidget {
  final ItemModel lostItem;

  const PossibleMatchesScreen({super.key, required this.lostItem});

  @override
  Widget build(BuildContext context) {
    final matches = MatchHelper.findPossibleMatches(
      lostItem: lostItem,
      allItems: sampleItems,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Possible Matches'),
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
                  colors: [Color(0xFF6C63FF), Color(0xFFFF7EB3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Smart Match ✨',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'LostLink analysed found items that may match your lost ${lostItem.name}.',
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
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology_rounded,
                    color: Color(0xFF6C63FF),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Matching is based on item name, category, colour, location, and description similarity.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: matches.isEmpty
                  ? const Center(
                      child: Text(
                        'No possible matches found yet.',
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final match = matches[index];

                        return ItemCard(
                          item: match.item,
                          matchScore: match.score,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ItemDetailScreen(item: match.item),
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
