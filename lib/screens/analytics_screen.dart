import 'package:flutter/material.dart';

import '../data/sample_items.dart';
import '../data/sample_claims.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = <String, int>{};
    final locations = <String, int>{};
    for (final item in sampleItems) {
      categories[item.category] = (categories[item.category] ?? 0) + 1;
      locations[item.location] = (locations[item.location] ?? 0) + 1;
    }

    final returnedCount = sampleItems
        .where((item) => item.status == 'Returned' || item.status == 'Claimed')
        .length;
    final pendingCount = sampleClaims
        .where((claim) => claim.status == 'Pending')
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(label: 'Returned', value: '$returnedCount'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(label: 'Pending', value: '$pendingCount'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionCard(title: 'Most Common Categories', values: categories),
          const SizedBox(height: 14),
          SectionCard(title: 'Most Common Locations', values: locations),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;

  const StatCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final Map<String, int> values;

  const SectionCard({super.key, required this.title, required this.values});

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Text('No data yet.')
            else
              for (final entry in entries.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.key)),
                      Text('${entry.value}'),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
