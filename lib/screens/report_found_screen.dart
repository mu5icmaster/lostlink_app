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

class ReportFoundScreen extends StatefulWidget {
  final UserModel currentUser;

  const ReportFoundScreen({super.key, required this.currentUser});

  @override
  State<ReportFoundScreen> createState() => _ReportFoundScreenState();
}

class _ReportFoundScreenState extends State<ReportFoundScreen> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController keptAtController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final ImagePicker imagePicker = ImagePicker();

  String selectedCategory = 'ID Card';
  XFile? selectedImage;
  bool isSubmitting = false;
  bool categoryWasManuallySelected = false;
  DateTime eventDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    contactController.text = widget.currentUser.contactNumber.trim();
    itemNameController.addListener(_suggestCategoryWhileTyping);
    descriptionController.addListener(_suggestCategoryWhileTyping);
  }

  void _suggestCategoryWhileTyping() {
    if (categoryWasManuallySelected) return;
    final suggestion = ItemFormHelper.suggestCategory(
      '${itemNameController.text} ${descriptionController.text}',
    );
    if (suggestion != 'Others' && suggestion != selectedCategory && mounted) {
      setState(() => selectedCategory = suggestion);
    }
  }

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
      categoryWasManuallySelected = false;
    });
  }

  String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  Future<void> chooseEventDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: eventDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'When was the item found?',
    );
    if (selected != null && mounted) setState(() => eventDate = selected);
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

  Future<void> submitFoundItem() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

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
      date: ItemFormHelper.formatDate(eventDate),
      type: 'found',
      status: 'Available',
      imageEmoji: ItemFormHelper.emojiForCategory(selectedCategory),
      imageUrl: imageUrl,
      cloudinaryPublicId: cloudinaryPublicId,
      localImagePath: selectedImage?.path,
      reporterName: widget.currentUser.name,
      reporterEmail: widget.currentUser.email,
      reporterUid: FirebaseItemService.currentUid ?? '',
      reporterRole: widget.currentUser.role,
      contactInfo: contactController.text.trim(),
      keptAt: keptAtController.text.trim(),
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
    );

    var itemToSave = newItem;
    var remoteMessage = 'Found item reported successfully.';

    try {
      itemToSave = await FirebaseItemService.uploadItem(
        item: newItem,
        includeCreatedAt: true,
      );
      if (!FirebaseItemService.lastFirestoreWriteSucceeded) {
        remoteMessage =
            'Found item saved locally. Firestore sync did not complete.';
      }
    } catch (_) {
      remoteMessage = 'Found item saved locally. Firestore save failed.';
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
    keptAtController.clear();
    contactController.clear();

    setState(() {
      selectedCategory = 'ID Card';
      categoryWasManuallySelected = false;
      eventDate = DateTime.now();
      contactController.text = widget.currentUser.contactNumber.trim();
      selectedImage = null;
      isSubmitting = false;
    });
  }

  @override
  void dispose() {
    itemNameController.removeListener(_suggestCategoryWhileTyping);
    descriptionController.removeListener(_suggestCategoryWhileTyping);
    itemNameController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    colorController.dispose();
    keptAtController.dispose();
    contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Report Found Item'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: AutofillGroup(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4DB6AC), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Found something?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Upload the item details so the owner can find it faster.',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FormSectionTitle(
                        icon: Icons.inventory_2_outlined,
                        title: 'Item details',
                        subtitle:
                            'Describe the item so its owner can identify it.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: itemNameController,
                        textInputAction: TextInputAction.next,
                        validator: (value) => requiredField(value, 'Item name'),
                        decoration: customInputDecoration(
                          'Item Name',
                          'Example: Student ID card',
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
                                  categoryWasManuallySelected = true;
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
                      TextFormField(
                        controller: colorController,
                        textInputAction: TextInputAction.next,
                        validator: (value) => requiredField(value, 'Colour'),
                        decoration: customInputDecoration(
                          'Colour',
                          'Example: Black, blue, pink',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: locationController,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            requiredField(value, 'Found location'),
                        decoration: customInputDecoration(
                          'Found Location',
                          'Example: Library Level 2',
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: isSubmitting ? null : chooseEventDate,
                        borderRadius: BorderRadius.circular(18),
                        child: InputDecorator(
                          decoration:
                              customInputDecoration(
                                'Date found',
                                'Select date',
                              ).copyWith(
                                prefixIcon: const Icon(Icons.event_outlined),
                                suffixIcon: const Icon(
                                  Icons.edit_calendar_outlined,
                                ),
                              ),
                          child: Text(ItemFormHelper.formatDate(eventDate)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 4,
                        minLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) =>
                            requiredField(value, 'Description'),
                        decoration: customInputDecoration(
                          'Description',
                          'Example: Found near the table after class',
                        ),
                      ),
                      const SizedBox(height: 24),
                      const FormSectionTitle(
                        icon: Icons.place_outlined,
                        title: 'Collection details',
                        subtitle: 'Help the owner know where to retrieve it.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: keptAtController,
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            requiredField(value, 'Item storage location'),
                        decoration: customInputDecoration(
                          'Where Item Is Kept',
                          'Example: Security office or admin counter',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: contactController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        validator: (value) =>
                            requiredField(value, 'Contact information'),
                        decoration:
                            customInputDecoration(
                              'Contact Information',
                              'Phone number for follow-up',
                            ).copyWith(
                              prefixIcon: const Icon(Icons.phone_outlined),
                              suffixIcon: contactController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear contact',
                                      onPressed: isSubmitting
                                          ? null
                                          : () => setState(
                                              contactController.clear,
                                            ),
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                            ),
                      ),
                      const SizedBox(height: 24),
                      const FormSectionTitle(
                        icon: Icons.add_a_photo_outlined,
                        title: 'Photo (optional)',
                        subtitle: 'A clear photo helps the owner recognize it.',
                      ),
                      const SizedBox(height: 16),
                      PhotoPickerPanel(
                        selectedImage: selectedImage,
                        onTap: isSubmitting ? null : snapPicture,
                        onRemove: selectedImage == null || isSubmitting
                            ? null
                            : () => setState(() => selectedImage = null),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : submitFoundItem,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF4DB6AC),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            isSubmitting
                                ? 'Submitting...'
                                : 'Publish Found Report',
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
        ),
      ),
    );
  }
}

class PhotoPickerPanel extends StatelessWidget {
  final XFile? selectedImage;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const PhotoPickerPanel({
    super.key,
    required this.selectedImage,
    required this.onTap,
    required this.onRemove,
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
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(selectedImage!.path), fit: BoxFit.cover),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton.filled(
                      tooltip: 'Remove photo',
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class FormSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const FormSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colors.onPrimaryContainer, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
