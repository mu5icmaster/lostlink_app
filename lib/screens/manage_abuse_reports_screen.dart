import 'package:flutter/material.dart';

import '../data/app_records.dart';
import '../services/firebase_item_service.dart';
import '../services/storage_service.dart';

class ManageAbuseReportsScreen extends StatefulWidget {
  const ManageAbuseReportsScreen({super.key});

  @override
  State<ManageAbuseReportsScreen> createState() =>
      _ManageAbuseReportsScreenState();
}

class _ManageAbuseReportsScreenState extends State<ManageAbuseReportsScreen> {
  Future<void> closeReport(int index) async {
    setState(() {
      abuseReports[index].status = 'Closed';
    });
    await StorageService.saveAbuseReports();
    await FirebaseItemService.uploadAbuseReport(abuseReports[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Abuse Reports')),
      body: abuseReports.isEmpty
          ? const Center(child: Text('No abuse reports submitted.'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: abuseReports.length,
              itemBuilder: (context, index) {
                final report = abuseReports[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.itemName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text('${report.reason} • ${report.status}'),
                        const SizedBox(height: 8),
                        Text(report.details),
                        const SizedBox(height: 8),
                        Text(
                          'Reported by ${report.reporterEmail} on ${report.createdAt}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        if (report.status != 'Closed') ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => closeReport(index),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Mark Closed'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
