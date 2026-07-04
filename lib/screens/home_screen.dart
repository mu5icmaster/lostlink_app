import 'package:flutter/material.dart';

import '../data/sample_claims.dart';
import '../data/sample_items.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firebase_item_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/item_form_helper.dart';
import '../widgets/activity_card.dart';
import '../widgets/home_menu_card.dart';
import '../widgets/status_chip.dart';
import 'admin_dashboard_screen.dart';
import 'campus_map_screen.dart';
import 'found_item_screen.dart';
import 'login_screen.dart';
import 'lost_item_screen.dart';
import 'my_reports_screen.dart';
import 'my_claims_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'report_found_screen.dart';
import 'report_lost_screen.dart';
import 'item_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel currentUser;

  const HomeScreen({super.key, required this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool get isAdmin => widget.currentUser.role == 'Admin';

  Future<void> goToPage(BuildContext context, Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (!mounted) return;
    setState(() {});
  }

  Future<void> logout(BuildContext context) async {
    await NotificationService.dispose();
    await StorageService.clearPrivateSessionData();
    await FirebaseItemService.signOut();
    AuthService.currentUser = null;
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  int get foundTodayCount {
    final today = ItemFormHelper.formattedToday();
    return sampleItems.where((item) {
      return item.type == 'found' && item.date == today;
    }).length;
  }

  int get pendingClaimsCount {
    return sampleClaims
        .where(
          (claim) =>
              claim.claimantEmail == widget.currentUser.email &&
              claim.status == 'Pending',
        )
        .length;
  }

  List<ItemModel> get recentItems {
    return sampleItems.reversed.take(3).toList();
  }

  List<ItemModel> get myItems {
    return sampleItems
        .where((item) => item.reporterEmail == widget.currentUser.email)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LostLink',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.currentUser.role} • ${widget.currentUser.email}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => goToPage(
                      context,
                      ProfileScreen(currentUser: widget.currentUser),
                    ),
                    icon: const Icon(Icons.person_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => goToPage(context, const SettingsScreen()),
                    icon: const Icon(Icons.settings_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => goToPage(
                      context,
                      NotificationsScreen(currentUser: widget.currentUser),
                    ),
                    icon: const Icon(Icons.notifications_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => logout(context),
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2F6F73), Color(0xFF6C63FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2F6F73).withValues(alpha: 0.22),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${widget.currentUser.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Report missing items, browse found items, and track claims from one campus-only workspace.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        StatusChip(
                          text: '$foundTodayCount found today',
                          icon: Icons.check_circle_outline_rounded,
                        ),
                        StatusChip(
                          text: '$pendingClaimsCount of my claims pending',
                          icon: Icons.pending_actions_rounded,
                        ),
                        StatusChip(
                          text: '${myItems.length} my reports',
                          icon: Icons.inventory_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.04,
                children: [
                  HomeMenuCard(
                    title: 'Report Lost',
                    subtitle: 'Submit missing item',
                    icon: Icons.search_rounded,
                    color: const Color(0xFFFF8A65),
                    onTap: () => goToPage(
                      context,
                      ReportLostScreen(currentUser: widget.currentUser),
                    ),
                  ),
                  HomeMenuCard(
                    title: 'Report Found',
                    subtitle: 'Log a found item',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF4DB6AC),
                    onTap: () => goToPage(
                      context,
                      ReportFoundScreen(currentUser: widget.currentUser),
                    ),
                  ),
                  HomeMenuCard(
                    title: 'Lost Items',
                    subtitle: 'Browse reports',
                    icon: Icons.list_alt_rounded,
                    color: const Color(0xFFEF5350),
                    onTap: () => goToPage(context, const LostItemsScreen()),
                  ),
                  HomeMenuCard(
                    title: 'Found Items',
                    subtitle: 'Claim available items',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF42A5F5),
                    onTap: () => goToPage(context, const FoundItemsScreen()),
                  ),
                  HomeMenuCard(
                    title: 'My Reports',
                    subtitle: 'Track your posts',
                    icon: Icons.fact_check_rounded,
                    color: const Color(0xFF7E57C2),
                    onTap: () => goToPage(
                      context,
                      MyReportsScreen(currentUser: widget.currentUser),
                    ),
                  ),
                  HomeMenuCard(
                    title: 'My Claims',
                    subtitle: 'Track claim status',
                    icon: Icons.assignment_turned_in_outlined,
                    color: const Color(0xFF00897B),
                    onTap: () => goToPage(
                      context,
                      MyClaimsScreen(currentUser: widget.currentUser),
                    ),
                  ),
                  HomeMenuCard(
                    title: 'Campus Map',
                    subtitle: 'View key places',
                    icon: Icons.map_rounded,
                    color: const Color(0xFF5C6BC0),
                    onTap: () => goToPage(context, const CampusMapScreen()),
                  ),
                  if (isAdmin)
                    HomeMenuCard(
                      title: 'Admin Panel',
                      subtitle: 'Manage records',
                      icon: Icons.admin_panel_settings_rounded,
                      color: const Color(0xFF22223B),
                      onTap: () =>
                          goToPage(context, const AdminDashboardScreen()),
                    ),
                ],
              ),
              const SizedBox(height: 26),
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              if (recentItems.isEmpty)
                const Text(
                  'No reports yet.',
                  style: TextStyle(color: Colors.black54),
                )
              else
                for (final item in recentItems) ...[
                  ActivityCard(
                    icon: item.type == 'lost'
                        ? Icons.search_rounded
                        : Icons.inventory_2_rounded,
                    title:
                        '${item.name} ${item.type == 'lost' ? 'reported lost' : 'reported found'}',
                    subtitle: '${item.location} • ${item.date}',
                    iconColor: item.type == 'lost'
                        ? const Color(0xFFFF8A65)
                        : const Color(0xFF4DB6AC),
                    onTap: () =>
                        goToPage(context, ItemDetailScreen(item: item)),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
