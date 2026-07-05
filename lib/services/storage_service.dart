import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_claims.dart';
import '../data/sample_items.dart';
import '../data/app_records.dart';
import '../models/abuse_report_model.dart';
import '../models/chat_message_model.dart';
import '../models/claim_model.dart';
import '../models/item_model.dart';
import '../models/thank_you_model.dart';
import 'firebase_item_service.dart';

class StorageService {
  static const String _itemsKey = 'lost_link_items';
  static const String _claimsKey = 'lost_link_claims';
  static const String _abuseReportsKey = 'lost_link_abuse_reports';
  static const String _thankYouMessagesKey = 'lost_link_thank_you_messages';
  static const String _chatMessagesKey = 'lost_link_chat_messages';

  static Future<void> loadData({bool syncCloud = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getString(_itemsKey);
    final claimsJson = prefs.getString(_claimsKey);
    final abuseReportsJson = prefs.getString(_abuseReportsKey);
    final thankYouMessagesJson = prefs.getString(_thankYouMessagesKey);
    final chatMessagesJson = prefs.getString(_chatMessagesKey);

    final decodedItems = _decodeList(itemsJson);
    if (decodedItems != null) {
      sampleItems
        ..clear()
        ..addAll(_parseRecords(decodedItems, ItemModel.fromJson));
    }

    final decodedClaims = _decodeList(claimsJson);
    if (decodedClaims != null) {
      sampleClaims
        ..clear()
        ..addAll(
          _parseRecords(
            decodedClaims,
            (claim) => ClaimModel.fromJson(claim, sampleItems),
          ),
        );
    }

    final decodedReports = _decodeList(abuseReportsJson);
    if (decodedReports != null) {
      abuseReports
        ..clear()
        ..addAll(_parseRecords(decodedReports, AbuseReportModel.fromJson));
    }

    final decodedThankYouMessages = _decodeList(thankYouMessagesJson);
    if (decodedThankYouMessages != null) {
      thankYouMessages
        ..clear()
        ..addAll(
          _parseRecords(decodedThankYouMessages, ThankYouModel.fromJson),
        );
    }

    final decodedChatMessages = _decodeList(chatMessagesJson);
    if (decodedChatMessages != null) {
      chatMessages
        ..clear()
        ..addAll(_parseRecords(decodedChatMessages, ChatMessageModel.fromJson));
    }

    if (syncCloud) await syncFromCloud();
    await expireOldItems();
  }

  static Future<void> syncFromCloud() async {
    await FirebaseItemService.initialize();
    if (!FirebaseItemService.isFirestoreAvailable) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final uid = FirebaseItemService.currentUid;
      if (uid == null) return;
      final isAdmin = FirebaseItemService.currentEmail == 'admin@campus.edu.my';
      final ownedClaims = isAdmin
          ? await firestore.collection('claims').get()
          : await firestore
                .collection('claims')
                .where('itemOwnerUid', isEqualTo: uid)
                .get();
      final submittedClaims = isAdmin
          ? ownedClaims
          : await firestore
                .collection('claims')
                .where('claimantUid', isEqualTo: uid)
                .get();
      final privateItemSnapshots = isAdmin
          ? [await firestore.collection('itemPrivate').get()]
          : await Future.wait([
              firestore
                  .collection('itemPrivate')
                  .where('ownerUid', isEqualTo: uid)
                  .get(),
              firestore
                  .collection('itemPrivate')
                  .where('approvedClaimantUids', arrayContains: uid)
                  .get(),
            ]);
      final results = await Future.wait([
        firestore.collection('items').get(),
        isAdmin
            ? firestore.collection('abuseReports').get()
            : firestore
                  .collection('abuseReports')
                  .where('reporterUid', isEqualTo: uid)
                  .get(),
        firestore
            .collection('thankYouMessages')
            .where(
              Filter.or(
                Filter('fromUid', isEqualTo: uid),
                Filter('toUid', isEqualTo: uid),
              ),
            )
            .get(),
      ]);

      final privateItems = <String, Map<String, dynamic>>{
        for (final doc in privateItemSnapshots.expand(
          (snapshot) => snapshot.docs,
        ))
          doc.id: doc.data(),
      };
      final cloudItems = results[0].docs.map((doc) {
        final data = {...doc.data(), ...?privateItems[doc.id]};
        return ItemModel.fromJson(data);
      }).toList();
      final mergedItems = <String, ItemModel>{
        for (final item in sampleItems) item.id: item,
        for (final item in cloudItems) item.id: item,
      }.values.toList();
      final claimDocs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
        for (final doc in [...ownedClaims.docs, ...submittedClaims.docs])
          doc.id: doc,
      };
      final cloudClaims = claimDocs.values
          .map((doc) => ClaimModel.fromJson(doc.data(), mergedItems))
          .toList();
      final cloudReports = results[1].docs
          .map((doc) => AbuseReportModel.fromJson(doc.data()))
          .toList();
      final cloudThankYouMessages = results[2].docs
          .map((doc) => ThankYouModel.fromJson(doc.data()))
          .toList();

      sampleItems
        ..clear()
        ..addAll(mergedItems);
      final mergedClaims = <String, ClaimModel>{
        for (final claim in sampleClaims) claim.id: claim,
        for (final claim in cloudClaims) claim.id: claim,
      }.values;
      sampleClaims
        ..clear()
        ..addAll(mergedClaims);
      final mergedReports = <String, AbuseReportModel>{
        for (final report in abuseReports) report.id: report,
        for (final report in cloudReports) report.id: report,
      }.values;
      abuseReports
        ..clear()
        ..addAll(mergedReports);
      final mergedThanks = <String, ThankYouModel>{
        for (final message in thankYouMessages) message.id: message,
        for (final message in cloudThankYouMessages) message.id: message,
      }.values;
      thankYouMessages
        ..clear()
        ..addAll(mergedThanks);

      await saveAll();
    } on FirebaseException catch (error) {
      FirebaseItemService.lastFirestoreError = error.message ?? error.code;
    } catch (_) {
      FirebaseItemService.lastFirestoreError = 'Cloud data sync failed';
    }
  }

  static Future<void> saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedItems = jsonEncode(
      sampleItems.map((item) => item.toJson()).toList(),
    );

    await prefs.setString(_itemsKey, encodedItems);
  }

  static Future<void> saveClaims() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedClaims = jsonEncode(
      sampleClaims.map((claim) => claim.toJson()).toList(),
    );

    await prefs.setString(_claimsKey, encodedClaims);
  }

  static Future<void> saveAbuseReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _abuseReportsKey,
      jsonEncode(abuseReports.map((report) => report.toJson()).toList()),
    );
  }

  static Future<void> saveThankYouMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _thankYouMessagesKey,
      jsonEncode(thankYouMessages.map((message) => message.toJson()).toList()),
    );
  }

  static Future<void> saveChatMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chatMessagesKey,
      jsonEncode(chatMessages.map((message) => message.toJson()).toList()),
    );
  }

  static Future<int> expireOldItems({int days = 90}) async {
    var changed = 0;
    final now = DateTime.now();
    for (final item in sampleItems) {
      final parsedDate = item.createdAtMillis == null
          ? _parseDisplayDate(item.date)
          : DateTime.fromMillisecondsSinceEpoch(item.createdAtMillis!);
      if (parsedDate == null) continue;

      final age = now.difference(parsedDate).inDays;
      final canExpire =
          item.status != 'Claimed' &&
          item.status != 'Returned' &&
          item.status != 'Expired';

      if (age >= days && canExpire) {
        item.status = 'Expired';
        changed++;
      }
    }

    if (changed > 0) {
      await saveItems();
    }
    return changed;
  }

  static Future<void> saveAll() async {
    await saveItems();
    await saveClaims();
    await saveAbuseReports();
    await saveThankYouMessages();
    await saveChatMessages();
  }

  /// Removes user-specific records from a shared device while retaining the
  /// public item catalogue. Cloud records are loaded again for the next user.
  static Future<void> clearPrivateSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_itemsKey),
      prefs.remove(_claimsKey),
      prefs.remove(_abuseReportsKey),
      prefs.remove(_thankYouMessagesKey),
      prefs.remove(_chatMessagesKey),
    ]);
    sampleItems.clear();
    sampleClaims.clear();
    abuseReports.clear();
    thankYouMessages.clear();
    chatMessages.clear();
  }

  static DateTime? _parseDisplayDate(String value) {
    final parts = value.split(' ');
    if (parts.length != 3) return null;

    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    final day = int.tryParse(parts[0]);
    final month = months[parts[1]];
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  static List<dynamic>? _decodeList(String? value) {
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is List<dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static List<T> _parseRecords<T>(
    List<dynamic> records,
    T Function(Map<String, dynamic>) parser,
  ) {
    final parsed = <T>[];
    for (final record in records) {
      try {
        if (record is Map<String, dynamic>) parsed.add(parser(record));
      } catch (_) {
        // Skip only the damaged record so valid local data remains usable.
      }
    }
    return parsed;
  }
}
