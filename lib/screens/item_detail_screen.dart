import 'dart:io';

import 'package:flutter/material.dart';

import '../models/item_model.dart';
import '../models/claim_model.dart';
import '../data/sample_claims.dart';
import '../services/auth_service.dart';
import '../services/firebase_item_service.dart';
import '../services/storage_service.dart';
import 'claim_request_screen.dart';
import 'item_chat_screen.dart';
import 'possible_matches_screen.dart';
import 'report_abuse_screen.dart';
import 'thank_you_screen.dart';
import 'manage_claims_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  ItemModel get item => widget.item;

  bool get isOwner {
    final user = AuthService.currentUser;
    final uid = FirebaseItemService.currentUid;
    return user != null &&
        ((uid != null && item.reporterUid == uid) ||
            item.reporterEmail == user.email);
  }

  bool get isAdmin => AuthService.currentUser?.role == 'Admin';

  ClaimModel? get activeClaim {
    final user = AuthService.currentUser;
    if (user == null) return null;
    for (final claim in sampleClaims) {
      if (claim.item.id == item.id &&
          claim.claimantEmail == user.email &&
          (claim.status == 'Pending' || claim.status == 'Approved')) {
        return claim;
      }
    }
    return null;
  }

  bool get hasActiveClaim => activeClaim != null;

  bool get hasApprovedClaim {
    final user = AuthService.currentUser;
    if (user == null) return false;
    return sampleClaims.any(
      (claim) =>
          claim.item.id == item.id &&
          claim.claimantEmail == user.email &&
          (claim.status == 'Approved' || claim.status == 'Collected'),
    );
  }

  bool get canSeePrivateDetails => isOwner || isAdmin || hasApprovedClaim;
  bool get canChat => activeClaim != null;

  Future<void> updateStatus(String status) async {
    setState(() => item.status = status);
    await StorageService.saveItems();
    await FirebaseItemService.uploadItem(item: item);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Report updated to $status.')));
  }

  Color getThemeColor() {
    if (item.type == 'lost') {
      return const Color(0xFFFF8A65);
    } else {
      return const Color(0xFF4DB6AC);
    }
  }

  Widget buildItemImage() {
    final imageUrl = item.imageUrl;
    final localImagePath = item.localImagePath;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          imageUrl,
          height: 210,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => buildEmoji(),
        ),
      );
    }

    if (localImagePath != null && localImagePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.file(
          File(localImagePath),
          height: 210,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => buildEmoji(),
        ),
      );
    }

    return buildEmoji();
  }

  Widget buildEmoji() {
    return Text(item.imageEmoji, style: const TextStyle(fontSize: 70));
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = getThemeColor();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Item Details'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  buildItemImage(),
                  const SizedBox(height: 14),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  DetailRow(
                    icon: Icons.category_rounded,
                    label: 'Category',
                    value: item.category,
                  ),
                  DetailRow(
                    icon: Icons.palette_rounded,
                    label: 'Colour',
                    value: item.color,
                  ),
                  DetailRow(
                    icon: Icons.location_on_rounded,
                    label: 'Location',
                    value: item.location,
                  ),
                  DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: item.date,
                  ),
                  DetailRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Description',
                    value: item.description,
                  ),
                  if (canSeePrivateDetails &&
                      item.keptAt != null &&
                      item.keptAt!.isNotEmpty)
                    DetailRow(
                      icon: Icons.lock_rounded,
                      label: 'Kept At',
                      value: item.keptAt!,
                    ),
                  DetailRow(
                    icon: Icons.person_rounded,
                    label: 'Reporter',
                    value: item.reporterName.isEmpty
                        ? 'Not recorded'
                        : '${item.reporterName} (${item.reporterRole})',
                  ),
                  if (canSeePrivateDetails)
                    DetailRow(
                      icon: Icons.phone_rounded,
                      label: 'Contact',
                      value: item.contactInfo.isEmpty
                          ? 'Not recorded'
                          : item.contactInfo,
                    )
                  else
                    const DetailRow(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Private details',
                      value:
                          'Contact and collection details appear after claim approval.',
                    ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            if (item.type == 'lost')
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PossibleMatchesScreen(lostItem: item),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Find Possible Matches'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),

            if (item.type == 'found' &&
                item.status == 'Available' &&
                !isOwner &&
                !hasActiveClaim)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClaimRequestScreen(item: item),
                      ),
                    );
                  },
                  icon: const Icon(Icons.assignment_turned_in_rounded),
                  label: const Text('Claim This Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4DB6AC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            if (item.type == 'found' && isOwner) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageClaimsScreen(itemId: item.id),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Review claims'),
                ),
              ),
            ],
            if (isOwner &&
                (item.status == 'Missing' || item.status == 'Available')) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => updateStatus(
                    item.type == 'lost' ? 'Returned' : 'Withdrawn',
                  ),
                  icon: const Icon(Icons.task_alt_rounded),
                  label: Text(
                    item.type == 'lost'
                        ? 'Mark as resolved'
                        : 'Withdraw found report',
                  ),
                ),
              ),
            ],
            if (isOwner &&
                (item.status == 'Returned' || item.status == 'Withdrawn')) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => updateStatus(
                    item.type == 'lost' ? 'Missing' : 'Available',
                  ),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reopen report'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (canChat) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemChatScreen(
                              item: item,
                              conversationId: activeClaim!.id,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Chat'),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportAbuseScreen(item: item),
                        ),
                      );
                    },
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Report'),
                  ),
                ),
              ],
            ),
            if (item.status == 'Claimed' || item.status == 'Returned') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ThankYouScreen(item: item),
                      ),
                    );
                  },
                  icon: const Icon(Icons.favorite_border_rounded),
                  label: const Text('Send Thank You'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            child: Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.black45, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
