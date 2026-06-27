import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/sample_items.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import '../services/cloudinary_service.dart';
import '../services/firebase_item_service.dart';
import '../services/storage_service.dart';
import '../utils/item_form_helper.dart';

class ReportLostScreen extends StatefulWidget {
  final UserModel currentUser;

  const ReportLostScreen({super.key, required this.currentUser});

  @override
  State<ReportLostScreen> createState() => _ReportLostScreenState();
}

class _ReportLostScreenState extends State<ReportLostScreen> {
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final ImagePicker imagePicker = ImagePicker();

  String selectedCategory = 'ID Card';
  XFile? selectedImage;
  bool isSubmitting = false;

  final List<String> categories = [
    'ID Card',
    'Wallet',
    'Electronics',
    'Books',
    'Stationery',
    'Documents',
    'Bags',
    'Personal belongings',
    'Bottle',
    'Clothing',
    'Keys',
    'Others',
  ];

  Future<void> snapPicture() async {
    final image = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (image == null || !mounted) return;

    setState(() {
      selectedImage = image;
    });
  }

  void suggestCategory() {
    final suggestion = ItemFormHelper.suggestCategory(
      '${itemNameController.text} ${descriptionController.text}',
    );
    setState(() {
      selectedCategory = suggestion;
    });
  }

  Future<void> submitLostItem() async {
    if (itemNameController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty ||
        colorController.text.trim().isEmpty ||
        contactController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Text('Please fill in all fields'),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final imageFile = selectedImage == null ? null : File(selectedImage!.path);
    String? imageUrl;
    String? cloudinaryPublicId;

    if (imageFile != null) {
      try {
        final uploadResult = await CloudinaryService.uploadImage(imageFile);
        imageUrl = uploadResult.secureUrl;
        cloudinaryPublicId = uploadResult.publicId;
      } catch (error) {
        if (!mounted) return;
        setState(() {
          isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
        return;
      }
    }

    final newItem = ItemModel(
      id: ItemFormHelper.createId(),
      name: itemNameController.text.trim(),
      category: selectedCategory,
      color: colorController.text.trim(),
      location: locationController.text.trim(),
      description: descriptionController.text.trim(),
      date: ItemFormHelper.formattedToday(),
      type: 'lost',
      status: 'Missing',
      imageEmoji: ItemFormHelper.emojiForCategory(selectedCategory),
      imageUrl: imageUrl,
      cloudinaryPublicId: cloudinaryPublicId,
      localImagePath: selectedImage?.path,
      reporterName: widget.currentUser.name,
      reporterEmail: widget.currentUser.email,
      reporterRole: widget.currentUser.role,
      contactInfo: contactController.text.trim(),
    );

    var itemToSave = newItem;
    var remoteMessage = 'Lost item reported successfully.';

    try {
      itemToSave = await FirebaseItemService.uploadItem(
        item: newItem,
        includeCreatedAt: true,
      );
      if (!FirebaseItemService.lastFirestoreWriteSucceeded) {
        remoteMessage =
            'Lost item saved locally. Firestore sync did not complete.';
      }
    } catch (_) {
      remoteMessage = 'Lost item saved locally. Firestore save failed.';
    }

    sampleItems.add(itemToSave);
    await StorageService.saveItems();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(remoteMessage),
      ),
    );

    itemNameController.clear();
    descriptionController.clear();
    locationController.clear();
    colorController.clear();
    contactController.clear();

    setState(() {
      selectedCategory = 'ID Card';
      selectedImage = null;
      isSubmitting = false;
    });
  }

  InputDecoration customInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.4,
        ),
      ),
    );
  }

  @override
  void dispose() {
    itemNameController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    colorController.dispose();
    contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Lost Item'),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFFFF7EB3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lost something?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Drop the details below and let LostLink help others spot it faster.',
                    style: TextStyle(
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
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: itemNameController,
                    decoration: customInputDecoration(
                      'Item Name',
                      'Example: Black wallet',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: customInputDecoration(
                      'Category',
                      'Select category',
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              selectedCategory = value!;
                            });
                          },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: isSubmitting ? null : suggestCategory,
                      icon: const Icon(Icons.image_search_rounded),
                      label: const Text('Suggest category'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: locationController,
                    decoration: customInputDecoration(
                      'Last Seen Location',
                      'Example: Library or Cafeteria',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: colorController,
                    decoration: customInputDecoration(
                      'Colour',
                      'Example: Black, blue, pink',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: customInputDecoration(
                      'Description',
                      'Example: black leather wallet with my student ID inside',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: contactController,
                    keyboardType: TextInputType.phone,
                    decoration: customInputDecoration(
                      'Contact Information',
                      widget.currentUser.contactNumber.isEmpty
                          ? 'Phone or email for follow-up'
                          : widget.currentUser.contactNumber,
                    ),
                  ),
                  const SizedBox(height: 14),
                  PhotoPickerPanel(
                    selectedImage: selectedImage,
                    onTap: isSubmitting ? null : snapPicture,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : submitLostItem,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        isSubmitting ? 'Submitting...' : 'Submit Lost Item',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoPickerPanel extends StatelessWidget {
  final XFile? selectedImage;
  final VoidCallback? onTap;

  const PhotoPickerPanel({
    super.key,
    required this.selectedImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: selectedImage == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_rounded, size: 34),
                  SizedBox(height: 8),
                  Text('Choose item photo'),
                ],
              )
            : Image.file(File(selectedImage!.path), fit: BoxFit.cover),
      ),
    );
  }
}
