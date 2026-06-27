import 'package:flutter/material.dart';

import '../data/sample_claims.dart';
import '../data/sample_items.dart';
import 'analytics_screen.dart';
import 'manage_claims_screen.dart';
import 'manage_abuse_reports_screen.dart';
import 'manage_items_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void goToPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final lostCount = sampleItems.where((item) => item.type == 'lost').length;
    final foundCount = sampleItems.where((item) => item.type == 'found').length;
    final pendingClaims = sampleClaims
        .where((claim) => claim.status == 'Pending')
        .length;
    final claimedItems = sampleItems
        .where((item) => item.status == 'Claimed' || item.status == 'Returned')
        .length;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF22223B), Color(0xFF2F6F73)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Control Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Manage item reports, review claims, and monitor lost-and-found activity.',
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
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              StatTile(
                label: 'Lost',
                value: '$lostCount',
                color: const Color(0xFFFF8A65),
              ),
              StatTile(
                label: 'Found',
                value: '$foundCount',
                color: const Color(0xFF4DB6AC),
              ),
              StatTile(
                label: 'Pending Claims',
                value: '$pendingClaims',
                color: const Color(0xFFFFB74D),
              ),
              StatTile(
                label: 'Claimed/Returned',
                value: '$claimedItems',
                color: const Color(0xFF6C63FF),
              ),
            ],
          ),
          const SizedBox(height: 22),
          AdminMenuCard(
            title: 'Manage Claims',
            subtitle: 'Approve or reject user claim requests',
            icon: Icons.assignment_turned_in_rounded,
            color: const Color(0xFF6C63FF),
            onTap: () => goToPage(context, const ManageClaimsScreen()),
          ),
          const SizedBox(height: 14),
          AdminMenuCard(
            title: 'Manage Items',
            subtitle: 'View all lost and found item reports',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF4DB6AC),
            onTap: () => goToPage(context, const ManageItemsScreen()),
          ),
          const SizedBox(height: 14),
          AdminMenuCard(
            title: 'Analytics',
            subtitle: 'View category, location, and status trends',
            icon: Icons.analytics_rounded,
            color: const Color(0xFFFF8A65),
            onTap: () => goToPage(context, const AnalyticsScreen()),
          ),
          const SizedBox(height: 14),
          AdminMenuCard(
            title: 'Abuse Reports',
            subtitle: 'Review suspicious posts and false-claim reports',
            icon: Icons.flag_rounded,
            color: const Color(0xFFEF5350),
            onTap: () => goToPage(context, const ManageAbuseReportsScreen()),
          ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(Icons.analytics_rounded, color: color, size: 18),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class AdminMenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const AdminMenuCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
