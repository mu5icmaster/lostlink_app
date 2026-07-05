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
import '../models/notification_model.dart';
import '../firebase_options.dart';

class FirebaseItemService {
  static bool _initialized = false;
  static Object? _initializationError;
  static bool _firestoreDisabled = false;
  static bool lastFirestoreWriteSucceeded = false;
  static String? lastFirestoreError;
  static String? lastStorageError;
  static String? lastAuthError;
  static String? lastAuthErrorCode;

  static bool get isAvailable => _initialized;
  static bool get isFirestoreAvailable => _initialized && !_firestoreDisabled;
  static String? get lastInitializationError =>
      _initializationError?.toString();
  static String? get currentUid => FirebaseAuth.instance.currentUser?.uid;
  static String? get currentEmail => FirebaseAuth.instance.currentUser?.email;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (_initializationError != null) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
    } catch (error) {
      _initializationError = error;
      lastFirestoreError = error.toString();
    }
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

    final firebaseData = item.toJson()
      ..remove('localImagePath')
      ..remove('contactInfo')
      ..remove('keptAt');
    firebaseData.addAll({
      'title': item.name,
      'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      'createdByEmail': item.reporterEmail,
      'reporterUid': item.reporterUid.isEmpty
          ? FirebaseAuth.instance.currentUser?.uid ?? ''
          : item.reporterUid,
      'updatedAt': FieldValue.serverTimestamp(),
      // Remove legacy public copies now that these fields live in itemPrivate.
      'contactInfo': FieldValue.delete(),
      'keptAt': FieldValue.delete(),
    });
    if (includeCreatedAt) {
      firebaseData['createdAt'] = FieldValue.serverTimestamp();
    }

    lastFirestoreWriteSucceeded = await _safeFirestoreWrite(() async {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      batch.set(
        firestore.collection('items').doc(item.id),
        firebaseData,
        SetOptions(merge: true),
      );
      batch.set(firestore.collection('itemPrivate').doc(item.id), {
        'itemId': item.id,
        'ownerUid': item.reporterUid.isEmpty
            ? FirebaseAuth.instance.currentUser?.uid ?? ''
            : item.reporterUid,
        'contactInfo': item.contactInfo,
        'keptAt': item.keptAt,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await batch.commit();
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

    lastFirestoreWriteSucceeded = await _safeFirestoreWrite(() async {
      final firestore = FirebaseFirestore.instance;
      final claimRef = firestore.collection('claims').doc(claim.id);
      final existingClaim = await claimRef.get();
      final claimData = {
        ...claim.toJson(),
        'claimantUid': claim.claimantUid.isEmpty
            ? FirebaseAuth.instance.currentUser?.uid ?? ''
            : claim.claimantUid,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (existingClaim.exists) {
        await claimRef.set(claimData, SetOptions(merge: true));
        return;
      }

      final participants = [
        claim.claimantUid.isEmpty
            ? FirebaseAuth.instance.currentUser?.uid ?? ''
            : claim.claimantUid,
        claim.itemOwnerUid,
      ].where((uid) => uid.isNotEmpty).toSet().toList();
      final chat = firestore.collection('itemChats').doc(claim.id);
      final batch = firestore.batch();
      batch.set(claimRef, claimData);
      batch.set(chat, {
        'itemId': claim.item.id,
        'claimId': claim.id,
        'participantUids': participants,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    });
    return lastFirestoreWriteSucceeded;
  }

  static Future<bool> grantItemPrivateAccess({
    required String itemId,
    required String claimantUid,
  }) async {
    if (claimantUid.isEmpty) return false;
    await initialize();
    return _safeFirestoreWrite(() {
      return FirebaseFirestore.instance
          .collection('itemPrivate')
          .doc(itemId)
          .set({
            'approvedClaimantUids': FieldValue.arrayUnion([claimantUid]),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    });
  }

  static Future<bool> registerUser(
    UserModel user, {
    required String password,
  }) async {
    await initialize();
    _resetLastWrite();
    lastAuthError = null;
    lastAuthErrorCode = null;
    if (!_initialized) {
      lastAuthError = lastInitializationError ?? 'Firebase unavailable';
      return false;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );
      // Authentication is already complete at this point. A profile sync
      // failure must not make the caller retry account creation, because that
      // would only produce email-already-in-use for the account just created.
      await uploadUserProfile(user);
      return true;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: user.email,
            password: password,
          );
          await uploadUserProfile(user);
          return true;
        } on FirebaseAuthException catch (signInError) {
          lastAuthErrorCode = signInError.code;
          lastAuthError = signInError.message ?? signInError.code;
          return false;
        }
      }
      lastAuthErrorCode = error.code;
      lastAuthError = error.message ?? error.code;
      return false;
    }
  }

  static Future<bool> signInUser({
    required String email,
    required String password,
  }) async {
    await initialize();
    lastAuthError = null;
    lastAuthErrorCode = null;
    if (!_initialized) {
      lastAuthError = lastInitializationError ?? 'Firebase unavailable';
      return false;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (error) {
      lastAuthErrorCode = error.code;
      lastAuthError = error.message ?? error.code;
      return false;
    }
  }

  static Future<void> signOut() => FirebaseAuth.instance.signOut();

  static Future<void> sendPasswordReset(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(
      email: email.toLowerCase().trim(),
    );
  }

  static Future<bool> sendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    await user.reload();
    if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) return true;
    await FirebaseAuth.instance.currentUser!.sendEmailVerification();
    return true;
  }

  static Future<void> deleteCurrentAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final firestore = FirebaseFirestore.instance;
    final ownedItems = await firestore
        .collection('items')
        .where('reporterUid', isEqualTo: user.uid)
        .get();
    for (final item in ownedItems.docs) {
      final deleted = await deleteItem(item.id);
      if (!deleted) {
        throw StateError(lastFirestoreError ?? 'Could not delete owned items');
      }
    }

    final submittedClaims = await firestore
        .collection('claims')
        .where('claimantUid', isEqualTo: user.uid)
        .get();
    for (final claim in submittedClaims.docs) {
      await _deleteClaimConversation(claim.reference);
    }

    final cleanupSnapshots = await Future.wait([
      firestore
          .collection('notifications')
          .where('recipientUid', isEqualTo: user.uid)
          .get(),
      firestore
          .collection('abuseReports')
          .where('reporterUid', isEqualTo: user.uid)
          .get(),
      firestore
          .collection('thankYouMessages')
          .where('fromUid', isEqualTo: user.uid)
          .get(),
      firestore
          .collection('thankYouMessages')
          .where('toUid', isEqualTo: user.uid)
          .get(),
    ]);
    final batch = firestore.batch();
    final seen = <String>{};
    for (final snapshot in cleanupSnapshots) {
      for (final document in snapshot.docs) {
        if (seen.add(document.reference.path)) batch.delete(document.reference);
      }
    }
    batch.delete(firestore.collection('users').doc(user.uid));
    await batch.commit();

    try {
      await FirebaseStorage.instance
          .ref('profile_pictures/${user.uid}/profile.jpg')
          .delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
    await user.delete();
  }

  static Future<bool> applyClaimDecision({
    required Iterable<ClaimModel> claims,
    required ItemModel item,
    String? approvedClaimantUid,
  }) async {
    await initialize();
    _resetLastWrite();
    if (!isFirestoreAvailable) {
      lastFirestoreError = lastInitializationError ?? 'Firestore unavailable';
      return false;
    }

    lastFirestoreWriteSucceeded = await _safeFirestoreWrite(() async {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      for (final claim in claims) {
        batch.update(firestore.collection('claims').doc(claim.id), {
          'status': claim.status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final itemData = item.toJson()
        ..remove('localImagePath')
        ..remove('contactInfo')
        ..remove('keptAt');
      itemData.addAll({
        'title': item.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'contactInfo': FieldValue.delete(),
        'keptAt': FieldValue.delete(),
      });
      batch.set(
        firestore.collection('items').doc(item.id),
        itemData,
        SetOptions(merge: true),
      );
      if (approvedClaimantUid != null && approvedClaimantUid.isNotEmpty) {
        batch.set(
          firestore.collection('itemPrivate').doc(item.id),
          {
            'approvedClaimantUids': FieldValue.arrayUnion([
              approvedClaimantUid,
            ]),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    });
    return lastFirestoreWriteSucceeded;
  }

  static Future<void> _deleteClaimConversation(
    DocumentReference<Map<String, dynamic>> claimRef,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final chatRef = firestore.collection('itemChats').doc(claimRef.id);
    final messages = await chatRef.collection('messages').get();
    final batch = firestore.batch();
    for (final message in messages.docs) {
      batch.delete(message.reference);
    }
    batch.delete(chatRef);
    batch.delete(claimRef);
    await batch.commit();
  }

  static Future<UserModel?> loadUserProfile(String email) async {
    await initialize();
    if (!_initialized || FirebaseAuth.instance.currentUser == null) return null;

    try {
      final users = FirebaseFirestore.instance.collection('users');
      final uid = FirebaseAuth.instance.currentUser!.uid;
      var data = (await users.doc(uid).get()).data();
      final completeProfile =
          data != null &&
          data['name'] is String &&
          data['email'] is String &&
          data['role'] is String;
      // Read legacy email-keyed profiles during migration.
      if (!completeProfile) {
        data = (await users.doc(email.toLowerCase().trim()).get()).data();
      }
      if (data == null) return null;
      lastFirestoreError = null;
      return UserModel.fromJson(data);
    } on FirebaseException catch (error) {
      lastFirestoreError = error.message ?? error.code;
      return null;
    } catch (_) {
      lastFirestoreError = 'Could not load the user profile';
      return null;
    }
  }

  static Future<bool> uploadUserProfile(UserModel user) async {
    final data = user.toJson()..remove('password');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      lastFirestoreError = 'No authenticated user for profile sync';
      return false;
    }
    if (!isFirestoreAvailable) {
      lastFirestoreError = lastInitializationError ?? 'Firestore unavailable';
      return false;
    }

    lastFirestoreWriteSucceeded = await _safeFirestoreWrite(() {
      return FirebaseFirestore.instance.collection('users').doc(uid).set({
        ...data,
        'uid': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
            .doc(user.uid)
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

  static Future<bool> uploadNotification(NotificationModel notification) async {
    await initialize();
    if (!isFirestoreAvailable || notification.recipientUid.isEmpty) {
      return false;
    }
    return _safeFirestoreWrite(() {
      return FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id)
          .set({
            ...notification.toJson(),
            'createdByUid': FirebaseAuth.instance.currentUser?.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
    });
  }

  static Future<void> markNotificationRead(String id) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .doc(id)
        .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});
  }

  static Future<bool> deleteItem(String itemId) async {
    await initialize();
    _resetLastWrite();
    if (!isFirestoreAvailable) {
      lastFirestoreError = lastInitializationError ?? 'Firestore unavailable';
      return false;
    }

    lastFirestoreWriteSucceeded = await _safeFirestoreWrite(() async {
      final firestore = FirebaseFirestore.instance;
      final claims = await firestore
          .collection('claims')
          .where('itemId', isEqualTo: itemId)
          .get();
      final related = await Future.wait([
        firestore
            .collection('thankYouMessages')
            .where('itemId', isEqualTo: itemId)
            .get(),
      ]);
      final batch = firestore.batch();
      batch.delete(firestore.collection('items').doc(itemId));
      batch.delete(firestore.collection('itemPrivate').doc(itemId));
      for (final claim in claims.docs) {
        final chat = firestore.collection('itemChats').doc(claim.id);
        final messages = await chat.collection('messages').get();
        for (final message in messages.docs) {
          batch.delete(message.reference);
        }
        batch.delete(chat);
        batch.delete(claim.reference);
      }
      for (final snapshot in related) {
        for (final document in snapshot.docs) {
          batch.delete(document.reference);
        }
      }
      await batch.commit();
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
