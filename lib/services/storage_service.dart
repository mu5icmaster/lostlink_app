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

  static Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getString(_itemsKey);
    final claimsJson = prefs.getString(_claimsKey);
    final abuseReportsJson = prefs.getString(_abuseReportsKey);
    final thankYouMessagesJson = prefs.getString(_thankYouMessagesKey);
    final chatMessagesJson = prefs.getString(_chatMessagesKey);

    if (itemsJson != null) {
      final decodedItems = jsonDecode(itemsJson) as List<dynamic>;
      sampleItems
        ..clear()
        ..addAll(
          decodedItems.map(
            (item) => ItemModel.fromJson(item as Map<String, dynamic>),
          ),
        );
    }

    if (claimsJson != null) {
      final decodedClaims = jsonDecode(claimsJson) as List<dynamic>;
      sampleClaims
        ..clear()
        ..addAll(
          decodedClaims.map(
            (claim) =>
                ClaimModel.fromJson(claim as Map<String, dynamic>, sampleItems),
          ),
        );
    }

    if (abuseReportsJson != null) {
      final decodedReports = jsonDecode(abuseReportsJson) as List<dynamic>;
      abuseReports
        ..clear()
        ..addAll(
          decodedReports.map(
            (report) =>
                AbuseReportModel.fromJson(report as Map<String, dynamic>),
          ),
        );
    }

    if (thankYouMessagesJson != null) {
      final decodedMessages = jsonDecode(thankYouMessagesJson) as List<dynamic>;
      thankYouMessages
        ..clear()
        ..addAll(
          decodedMessages.map(
            (message) =>
                ThankYouModel.fromJson(message as Map<String, dynamic>),
          ),
        );
    }

    if (chatMessagesJson != null) {
      final decodedMessages = jsonDecode(chatMessagesJson) as List<dynamic>;
      chatMessages
        ..clear()
        ..addAll(
          decodedMessages.map(
            (message) =>
                ChatMessageModel.fromJson(message as Map<String, dynamic>),
          ),
        );
    }

    await expireOldItems();
    await syncFromCloud();
  }

  static Future<void> syncFromCloud() async {
    await FirebaseItemService.initialize();
    if (!FirebaseItemService.isFirestoreAvailable) return;

    try {
      final itemDocs = await FirebaseFirestore.instance
          .collection('items')
          .get();
      if (itemDocs.docs.isNotEmpty) {
        sampleItems
          ..clear()
          ..addAll(
            itemDocs.docs.map((doc) {
              return ItemModel.fromJson(doc.data());
            }),
          );
      }

      final claimDocs = await FirebaseFirestore.instance
          .collection('claims')
          .get();
      if (claimDocs.docs.isNotEmpty) {
        sampleClaims
          ..clear()
          ..addAll(
            claimDocs.docs.map((doc) {
              return ClaimModel.fromJson(doc.data(), sampleItems);
            }),
          );
      }

      final abuseReportDocs = await FirebaseFirestore.instance
          .collection('abuseReports')
          .get();
      if (abuseReportDocs.docs.isNotEmpty) {
        abuseReports
          ..clear()
          ..addAll(
            abuseReportDocs.docs.map((doc) {
              return AbuseReportModel.fromJson(doc.data());
            }),
          );
      }

      final thankYouDocs = await FirebaseFirestore.instance
          .collection('thankYouMessages')
          .get();
      if (thankYouDocs.docs.isNotEmpty) {
        thankYouMessages
          ..clear()
          ..addAll(
            thankYouDocs.docs.map((doc) {
              return ThankYouModel.fromJson(doc.data());
            }),
          );
      }

      final chatDocs = await FirebaseFirestore.instance
          .collectionGroup('messages')
          .get();
      if (chatDocs.docs.isNotEmpty) {
        chatMessages
          ..clear()
          ..addAll(
            chatDocs.docs.map((doc) {
              return ChatMessageModel.fromJson(doc.data());
            }),
          );
      }

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
      final parsedDate = _parseDisplayDate(item.date);
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
}
