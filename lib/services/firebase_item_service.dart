import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/item_model.dart';
import '../models/claim_model.dart';
import '../models/user_model.dart';
import '../models/abuse_report_model.dart';
import '../models/thank_you_model.dart';
import '../models/chat_message_model.dart';
import '../firebase_options.dart';

class FirebaseItemService {
  static bool _initialized = false;
  static Object? _initializationError;
  static bool _firestoreDisabled = false;
  static bool lastFirestoreWriteSucceeded = false;
  static String? lastFirestoreError;
  static String? lastStorageError;

  static bool get isAvailable => _initialized;
  static bool get isFirestoreAvailable => _initialized && !_firestoreDisabled;
  static String? get lastInitializationError =>
      _initializationError?.toString();

  static Future<void> initialize() async {
    if (_initialized) {
      await _ensureFirebaseAuth();
      return;
    }
    if (_initializationError != null) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await _ensureFirebaseAuth();
      _initialized = true;
    } catch (error) {
      _initializationError = error;
      lastFirestoreError = error.toString();
    }
  }

  static Future<void> _ensureFirebaseAuth() async {
    if (FirebaseAuth.instance.currentUser != null) return;
    await FirebaseAuth.instance.signInAnonymously();
  }

  static Future<ItemModel> uploadItem({
    required ItemModel item,
    bool includeCreatedAt = false,
  }) async {
    await initialize();
    _resetLastWrite();
    if (!_initialized) {
      lastFirestoreError = lastInitializationError ?? 'Firebase unavailable';
      return item;
    }

    final firebaseData = item.toJson()..remove('localImagePath');
    firebaseData.addAll({
      'title': item.name,
      'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      'createdByEmail': item.reporterEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (includeCreatedAt) {
      firebaseData['createdAt'] = FieldValue.serverTimestamp();
    }

    lastFirestoreWriteSucceeded = await _safeFirestoreWrite(() {
      return FirebaseFirestore.instance
          .collection('items')
          .doc(item.id)
          .set(firebaseData, SetOptions(merge: true));
    });

    return item;
  }

  static Future<bool> uploadClaim(ClaimModel claim) async {
    await initialize();
    _resetLastWrite();
    if (!isFirestoreAvailable) {
      lastFirestoreError = lastInitializationError ?? 'Firestore unavailable';
      return false;
    }

    lastFirestoreWriteSucceeded = await _safeFirestoreWrite(() {
      return FirebaseFirestore.instance.collection('claims').doc(claim.id).set({
        ...claim.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    return lastFirestoreWriteSucceeded;
  }

  static Future<bool> uploadUser(UserModel user) async {
    await initialize();
    _resetLastWrite();
    if (!isFirestoreAvailable) {
      lastFirestoreError = lastInitializationError ?? 'Firestore unavailable';
      return false;
    }

    final data = user.toJson()..remove('password');
    lastFirestoreWriteSucceeded = await _safeFirestoreWrite(() {
      return FirebaseFirestore.instance.collection('users').doc(user.email).set(
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    });
    return lastFirestoreWriteSucceeded;
  }

  static Future<String?> uploadProfilePicture({
    required String userEmail,
    required File imageFile,
  }) async {
    await initialize();
    _resetLastWrite();
    lastStorageError = null;

    final user = FirebaseAuth.instance.currentUser;
    if (!_initialized || user == null) {
      lastStorageError = lastInitializationError ?? 'Firebase Auth unavailable';
      return null;
    }

    try {
      const fileName = 'profile.jpg';
      final storagePath = 'profile_pictures/${user.uid}/$fileName';
      final ref = FirebaseStorage.instance.ref(storagePath);
      await ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await ref.getDownloadURL();

      lastFirestoreWriteSucceeded = await _safeFirestoreWrite(() {
        return FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .set({
              'profileImageUrl': downloadUrl,
              'profileImagePath': storagePath,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      });

      return lastFirestoreWriteSucceeded ? downloadUrl : null;
    } on FirebaseException catch (error) {
      lastStorageError = error.message ?? error.code;
      return null;
    } catch (_) {
      lastStorageError = 'Profile picture upload failed';
      return null;
    }
  }

  static Future<bool> uploadAbuseReport(AbuseReportModel report) async {
    await initialize();
    _resetLastWrite();
    if (!isFirestoreAvailable) {
      lastFirestoreError = lastInitializationError ?? 'Firestore unavailable';
      return false;
    }

    lastFirestoreWriteSucceeded = await _safeFirestoreWrite(() {
      return FirebaseFirestore.instance
          .collection('abuseReports')
          .doc(report.id)
          .set({
            ...report.toJson(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    });
    return lastFirestoreWriteSucceeded;
  }

  static Future<bool> uploadThankYouMessage(ThankYouModel message) async {
    await initialize();
    _resetLastWrite();
    if (!isFirestoreAvailable) {
      lastFirestoreError = lastInitializationError ?? 'Firestore unavailable';
      return false;
    }

    lastFirestoreWriteSucceeded = await _safeFirestoreWrite(() {
      return FirebaseFirestore.instance
          .collection('thankYouMessages')
          .doc(message.id)
          .set({
            ...message.toJson(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    });
    return lastFirestoreWriteSucceeded;
  }

  static Future<bool> uploadChatMessage(ChatMessageModel message) async {
    await initialize();
    _resetLastWrite();
    if (!isFirestoreAvailable) {
      lastFirestoreError = lastInitializationError ?? 'Firestore unavailable';
      return false;
    }

    lastFirestoreWriteSucceeded = await _safeFirestoreWrite(() {
      return FirebaseFirestore.instance
          .collection('itemChats')
          .doc(message.itemId)
          .collection('messages')
          .doc(message.id)
          .set({
            ...message.toJson(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    });
    return lastFirestoreWriteSucceeded;
  }

  static Future<bool> deleteItem(String itemId) async {
    await initialize();
    _resetLastWrite();
    if (!isFirestoreAvailable) {
      lastFirestoreError = lastInitializationError ?? 'Firestore unavailable';
      return false;
    }

    lastFirestoreWriteSucceeded = await _safeFirestoreWrite(() {
      return FirebaseFirestore.instance
          .collection('items')
          .doc(itemId)
          .delete();
    });
    return lastFirestoreWriteSucceeded;
  }

  static void _resetLastWrite() {
    _firestoreDisabled = false;
    lastFirestoreWriteSucceeded = false;
    lastFirestoreError = null;
    lastStorageError = null;
  }

  static Future<bool> _safeFirestoreWrite(Future<void> Function() write) async {
    if (!isFirestoreAvailable) return false;

    try {
      await write();
      lastFirestoreError = null;
      return true;
    } on FirebaseException catch (error) {
      if (_isFirestoreConfigurationError(error)) {
        _firestoreDisabled = true;
      }
      lastFirestoreError = error.message ?? error.code;
      return false;
    } catch (_) {
      // Local-first app: failed remote sync should not block user workflows.
      lastFirestoreError = 'Remote sync failed';
      return false;
    }
  }

  static bool _isFirestoreConfigurationError(FirebaseException error) {
    final message = error.message?.toLowerCase() ?? '';
    return error.code == 'permission-denied' ||
        error.code == 'failed-precondition' ||
        message.contains('firestore api') ||
        message.contains('disabled');
  }
}
