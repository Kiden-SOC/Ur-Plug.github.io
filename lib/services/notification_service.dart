import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_item.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('notifications');

  Stream<AppNotification> get onNotification {
    return _collection
        .where('recipientUid', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .expand((snapshot) => snapshot.docChanges)
        .where((change) => change.type == DocumentChangeType.added)
        .map((change) =>
        AppNotification.fromFirestore(change.doc.id, change.doc.data()!));
  }

  Future<List<AppNotification>> fetchAll() async {
    final snapshot = await _collection
        .where('recipientUid', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AppNotification.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<void> markRead(String notificationId) async {
    await _collection.doc(notificationId).update({'isRead': true});
  }

  /// Live count of unread notifications, for badge display.
  Stream<int> get unreadCount {
    return _collection
        .where('recipientUid', isEqualTo: _uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markAllRead() async {
    final snapshot = await _collection
        .where('recipientUid', isEqualTo: _uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}