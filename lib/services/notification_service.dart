import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static StreamSubscription<String>? _tokenSubscription;

  static Future<void> initializeForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _saveToken(user.uid, token);

    await _tokenSubscription?.cancel();
    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) => _saveToken(user.uid, token),
    );
  }

  static Future<void> _saveToken(String uid, String token) {
    return FirebaseFirestore.instance.collection('users').doc(uid).set({
      'notificationTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
  }
}
