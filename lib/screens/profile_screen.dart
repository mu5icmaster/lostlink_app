import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/sample_claims.dart';
import '../data/sample_items.dart';
import '../models/user_model.dart';
import '../services/firebase_item_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel currentUser;

  const ProfileScreen({super.key, required this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker imagePicker = ImagePicker();
  bool isUploading = false;
  String? localProfileImageUrl;

  UserModel get currentUser => widget.currentUser;

  Future<void> uploadProfilePicture() async {
    final image = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image == null || !mounted) return;

    setState(() {
      isUploading = true;
    });

    final downloadUrl = await FirebaseItemService.uploadProfilePicture(
      userEmail: currentUser.email,
      imageFile: File(image.path),
    );

    if (!mounted) return;
    setState(() {
      isUploading = false;
      localProfileImageUrl = downloadUrl ?? localProfileImageUrl;
    });

    final message = downloadUrl == null
        ? 'Profile picture upload failed: ${FirebaseItemService.lastStorageError ?? FirebaseItemService.lastFirestoreError ?? 'check Firebase setup'}'
        : 'Profile picture updated.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myReports = sampleItems
        .where((item) => item.reporterEmail == currentUser.email)
        .length;
    final myClaims = sampleClaims
        .where((claim) => claim.contactInfo == currentUser.contactNumber)
        .length;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.email)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final name = data?['name'] as String? ?? currentUser.name;
          final role = data?['role'] as String? ?? currentUser.role;
          final email = data?['email'] as String? ?? currentUser.email;
          final contactNumber =
              data?['contactNumber'] as String? ?? currentUser.contactNumber;
          final profileImageUrl =
              localProfileImageUrl ?? data?['profileImageUrl'] as String?;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F6F73),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      backgroundImage: profileImageUrl == null
                          ? null
                          : NetworkImage(profileImageUrl),
                      child: profileImageUrl == null
                          ? const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 34,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            role,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            email,
                            style: const TextStyle(color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: isUploading ? null : uploadProfilePicture,
                  icon: isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera_rounded),
                  label: Text(
                    isUploading
                        ? 'Uploading...'
                        : profileImageUrl == null
                        ? 'Upload Profile Picture'
                        : 'Change Profile Picture',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ProfileRow(
                icon: Icons.email_rounded,
                label: 'Email',
                value: email,
              ),
              ProfileRow(
                icon: Icons.phone_rounded,
                label: 'Contact',
                value: contactNumber.isEmpty ? 'Not provided' : contactNumber,
              ),
              ProfileRow(
                icon: Icons.inventory_rounded,
                label: 'My Reported Items',
                value: '$myReports',
              ),
              ProfileRow(
                icon: Icons.assignment_turned_in_rounded,
                label: 'My Claim Requests',
                value: '$myClaims',
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const ProfileRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF2F6F73).withValues(alpha: 0.1),
            child: Icon(icon, color: const Color(0xFF2F6F73)),
          ),
          const SizedBox(width: 14),
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
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
