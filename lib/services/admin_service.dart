import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_exceptions.dart';
import '../models/user_model.dart';
import '../models/audit_log_entry.dart';
import '../models/dispute.dart';
import '../models/appeal.dart';

/// Central service for every admin-only operation.
///
/// Every method that changes something writes a matching [AuditLogEntry].
/// This is the app-layer half of the audit trail; the other half is
/// firestore.rules denying update/delete on `audit_logs` so the trail
/// can't be edited after the fact, even by an admin.
///
/// SECURITY: this class does not itself check "is the caller an admin?" —
/// that must be enforced by (a) the UI only being reachable after
/// AuthService.isCurrentUserAdmin() succeeds, and (b) Firestore rules
/// rejecting writes to admin-only collections from non-admin accounts.
/// Client-side checks alone are not real security; see SECURITY.md.
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------------------------------------------------------
  // Identity helpers
  // ---------------------------------------------------------------

  String get _adminUid => _auth.currentUser?.uid ?? 'unknown';

  Future<String> _adminName() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'Unknown admin';
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['fullName'] ?? _auth.currentUser?.email ?? 'Admin';
      }
    } catch (_) {
      // fall through to email/uid below
    }
    return _auth.currentUser?.email ?? 'Admin';
  }

  Future<void> _writeAuditLog({
    required String action,
    required String targetType,
    required String targetId,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    final adminName = await _adminName();
    final entry = AuditLogEntry(
      id: '',
      adminUid: _adminUid,
      adminName: adminName,
      action: action,
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      metadata: metadata,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('audit_logs').add(entry.toMap());
  }

  // ---------------------------------------------------------------
  // USERS & PROVIDERS DIRECTORY
  // ---------------------------------------------------------------

  /// All consumer/producer accounts from the `users` collection.
  Stream<List<UserModel>> usersStream() {
    return _firestore.collection('users').snapshots().map((snap) => snap.docs
        .map((d) => UserModel.fromMap(d.id, d.data()))
        .toList());
  }

  /// All provider business profiles from the `providers` collection, with
  /// the document id merged in as `uid` for convenience.
  Stream<List<Map<String, dynamic>>> providersStream() {
    return _firestore.collection('providers').snapshots().map((snap) => snap
        .docs
        .map((d) => {...d.data(), 'uid': d.id})
        .toList());
  }

  /// Suspend a consumer or provider account. Writes an audit log entry.
  /// [targetType] should be 'user' or 'provider'.
  Future<void> suspendAccount({
    required String uid,
    required String targetType,
    required String reason,
  }) async {
    try {
      final collection = targetType == 'provider' ? 'providers' : 'users';
      await _firestore.collection(collection).doc(uid).update({
        'accountStatus': 'suspended',
        'suspendedAt': FieldValue.serverTimestamp(),
        'suspensionReason': reason,
      });
      // If this account also has a provider profile, take it off the
      // marketplace immediately regardless of which collection was targeted.
      if (targetType == 'provider') {
        await _firestore.collection('providers').doc(uid).update({'available': false});
      }
      await _writeAuditLog(
        action: 'suspend_account',
        targetType: targetType,
        targetId: uid,
        reason: reason,
      );
    } on FirebaseException catch (_) {
      throw const AuthException('Could not suspend this account. Please try again.');
    }
  }

  Future<void> reinstateAccount({
    required String uid,
    required String targetType,
  }) async {
    try {
      final collection = targetType == 'provider' ? 'providers' : 'users';
      await _firestore.collection(collection).doc(uid).update({
        'accountStatus': 'active',
        'suspensionReason': FieldValue.delete(),
      });
      await _writeAuditLog(
        action: 'reinstate_account',
        targetType: targetType,
        targetId: uid,
      );
    } on FirebaseException catch (_) {
      throw const AuthException('Could not reinstate this account. Please try again.');
    }
  }

  // ---------------------------------------------------------------
  // PROVIDER VERIFICATION
  // ---------------------------------------------------------------

  /// Providers whose verificationStatus is 'pending', newest first.
  Stream<List<Map<String, dynamic>>> verificationQueueStream() {
    return _firestore
        .collection('providers')
        .where('verificationStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'uid': d.id}).toList());
  }

  Future<void> approveVerification(String providerUid) async {
    try {
      await _firestore.collection('providers').doc(providerUid).update({
        'verificationStatus': 'approved',
        'accountStatus': 'active',
      });
      await _writeAuditLog(
        action: 'approve_verification',
        targetType: 'provider',
        targetId: providerUid,
      );
    } on FirebaseException catch (_) {
      throw const AuthException('Could not approve this provider. Please try again.');
    }
  }

  Future<void> rejectVerification(String providerUid, String reason) async {
    try {
      await _firestore.collection('providers').doc(providerUid).update({
        'verificationStatus': 'rejected',
        'verificationNotes': reason,
        'available': false,
      });
      await _writeAuditLog(
        action: 'reject_verification',
        targetType: 'provider',
        targetId: providerUid,
        reason: reason,
      );
    } on FirebaseException catch (_) {
      throw const AuthException('Could not reject this provider. Please try again.');
    }
  }

  // ---------------------------------------------------------------
  // REVIEW MODERATION
  // ---------------------------------------------------------------
  //
  // NOTE: this app currently has two independent review-writing paths —
  // a Firestore subcollection (providers/{id}/reviews, written from the
  // customer-facing provider detail screen) and a separate REST-backed
  // flow (ReviewService / leave_review_screen.dart / reviews_list_screen.dart)
  // that isn't connected to Firestore at all. They don't share data. Admin
  // moderation here covers the Firestore-backed reviews, since that's the
  // one this app can act on directly. See CHANGES.md for the recommendation
  // to consolidate on a single review pipeline.

  /// All reviews across all providers, newest first. Requires the
  /// `reviews` collection group to be readable by admins (see
  /// firestore.rules).
  Stream<List<Map<String, dynamic>>> allReviewsStream() {
    return _firestore
        .collectionGroup('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final providerId = d.reference.parent.parent?.id ?? '';
              return {...d.data(), 'id': d.id, 'providerId': providerId};
            }).toList());
  }

  /// One row per provider that has at least one review: provider name,
  /// review count, when their newest review came in, and whether the admin
  /// has viewed this provider's reviews since that newest review arrived.
  ///
  /// "Unread" means: this provider has a review newer than the last time an
  /// admin opened their review list (or it's never been opened). Once
  /// viewed, the provider moves to "read" — but stays in this list either
  /// way, so past reviews are always still reachable, they just aren't
  /// flagged as new anymore.
  Stream<List<Map<String, dynamic>>> reviewsByProviderStream() {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();
    List<Map<String, dynamic>>? latestReviews;
    Map<String, dynamic>? latestProviders;
    Map<String, DateTime>? latestReads;

    void emit() {
      if (latestReviews == null || latestProviders == null || latestReads == null) return;

      final byProvider = <String, List<Map<String, dynamic>>>{};
      for (final r in latestReviews!) {
        byProvider.putIfAbsent(r['providerId'] as String, () => []).add(r);
      }

      final rows = byProvider.entries.map((e) {
        final providerId = e.key;
        final reviews = e.value;
        final newest = reviews.first['createdAt'];
        final newestAt = newest is Timestamp ? newest.toDate() : DateTime.now();
        final providerData = latestProviders![providerId] as Map<String, dynamic>?;
        final providerName = providerData?['businessName'] ?? 'Unknown business';
        final lastViewedAt = latestReads![providerId];
        final isUnread = lastViewedAt == null || newestAt.isAfter(lastViewedAt);

        return {
          'providerId': providerId,
          'providerName': providerName,
          'reviewCount': reviews.length,
          'latestReviewAt': newestAt,
          'isUnread': isUnread,
        };
      }).toList();

      rows.sort((a, b) {
        final unreadCompare = (b['isUnread'] as bool ? 1 : 0).compareTo(a['isUnread'] as bool ? 1 : 0);
        if (unreadCompare != 0) return unreadCompare;
        return (b['latestReviewAt'] as DateTime).compareTo(a['latestReviewAt'] as DateTime);
      });

      controller.add(rows);
    }

    final subs = <StreamSubscription>[];
    subs.add(allReviewsStream().listen((reviews) {
      latestReviews = reviews;
      emit();
    }));
    subs.add(_firestore.collection('providers').snapshots().listen((snap) {
      latestProviders = {for (final d in snap.docs) d.id: d.data()};
      emit();
    }));
    subs.add(_firestore.collection('admin_review_reads').snapshots().listen((snap) {
      latestReads = {
        for (final d in snap.docs)
          d.id: (d.data()['lastViewedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0)
      };
      emit();
    }));

    controller.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };
    return controller.stream;
  }

  /// Reviews for a single provider, newest first.
  Stream<List<Map<String, dynamic>>> providerReviewsStream(String providerId) {
    return _firestore
        .collection('providers')
        .doc(providerId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {...d.data(), 'id': d.id, 'providerId': providerId})
            .toList());
  }

  /// Marks the admin as having viewed this provider's reviews as of now.
  /// Any review posted after this moves the provider back to "unread".
  Future<void> markProviderReviewsRead(String providerId) async {
    try {
      await _firestore.collection('admin_review_reads').doc(providerId).set({
        'lastViewedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (_) {
      // Non-critical — the list will just re-show this provider as unread
      // next time. Don't interrupt the admin over it.
    }
  }

  /// Permanently deletes a review. A record of what it said is kept in the
  /// audit log (via [metadata]) so an appeal still has something to review
  /// even though the live document is gone.
  Future<void> deleteReview({
    required String providerId,
    required String reviewId,
    required String reason,
    Map<String, dynamic>? reviewSnapshot,
  }) async {
    try {
      await _firestore
          .collection('providers')
          .doc(providerId)
          .collection('reviews')
          .doc(reviewId)
          .delete();
      await _writeAuditLog(
        action: 'delete_review',
        targetType: 'review',
        targetId: reviewId,
        reason: reason,
        metadata: reviewSnapshot,
      );
    } on FirebaseException catch (_) {
      throw const AuthException('Could not delete this review. Please try again.');
    }
  }

  // ---------------------------------------------------------------
  // DISPUTES
  // ---------------------------------------------------------------

  Stream<List<Dispute>> disputesStream() {
    return _firestore
        .collection('disputes')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Dispute.fromMap(d.id, d.data())).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<void> resolveDispute({
    required String disputeId,
    required bool asResolved, // true = resolved, false = dismissed
    required String resolutionNotes,
  }) async {
    try {
      await _firestore.collection('disputes').doc(disputeId).update({
        'status': asResolved ? 'resolved' : 'dismissed',
        'resolutionNotes': resolutionNotes,
        'resolvedByAdminUid': _adminUid,
        'resolvedAt': Timestamp.fromDate(DateTime.now()),
      });
      await _writeAuditLog(
        action: asResolved ? 'resolve_dispute' : 'dismiss_dispute',
        targetType: 'dispute',
        targetId: disputeId,
        reason: resolutionNotes,
      );
    } on FirebaseException catch (_) {
      throw const AuthException('Could not update this dispute. Please try again.');
    }
  }

  Future<void> markDisputeUnderReview(String disputeId) async {
    try {
      await _firestore.collection('disputes').doc(disputeId).update({'status': 'underReview'});
    } on FirebaseException catch (_) {
      throw const AuthException('Could not update this dispute. Please try again.');
    }
  }

  // ---------------------------------------------------------------
  // APPEALS
  // ---------------------------------------------------------------

  Stream<List<Appeal>> appealsStream() {
    return _firestore
        .collection('appeals')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Appeal.fromMap(d.id, d.data())).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  /// Resolve an appeal. If [uphold] is true, the original action stands.
  /// If false (overturned), this also reverses the original action where
  /// possible (reinstates a suspended account).
  Future<void> resolveAppeal({
    required Appeal appeal,
    required bool uphold,
    required String reviewNotes,
  }) async {
    try {
      await _firestore.collection('appeals').doc(appeal.id).update({
        'status': uphold ? 'upheld' : 'overturned',
        'reviewedByAdminUid': _adminUid,
        'reviewNotes': reviewNotes,
        'resolvedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (!uphold && appeal.targetType == 'account_suspension') {
        // Best-effort reversal. We don't know if the account is a plain
        // user or a provider, so try both collections.
        await _firestore.collection('users').doc(appeal.submittedByUid).update({
          'accountStatus': 'active',
          'suspensionReason': FieldValue.delete(),
        }).catchError((_) {});
        await _firestore.collection('providers').doc(appeal.submittedByUid).update({
          'accountStatus': 'active',
          'available': true,
          'suspensionReason': FieldValue.delete(),
        }).catchError((_) {});
      }

      await _writeAuditLog(
        action: uphold ? 'uphold_appeal' : 'overturn_appeal',
        targetType: 'appeal',
        targetId: appeal.id,
        reason: reviewNotes,
      );
    } on FirebaseException catch (_) {
      throw const AuthException('Could not resolve this appeal. Please try again.');
    }
  }

  // ---------------------------------------------------------------
  // SYSTEM BROADCASTS
  // ---------------------------------------------------------------

  /// Sends a notification to every account matching [audience]
  /// ('consumers', 'providers', or 'all'), optionally narrowed to a
  /// single [district]. Returns how many recipients it reached.
  ///
  /// Batched in chunks of 400 writes (Firestore's batch limit is 500;
  /// 400 leaves headroom for the broadcast-log write in the same run).
  Future<int> sendBroadcast({
    required String title,
    required String body,
    required String audience,
    String? district,
  }) async {
    try {
      final List<String> recipientUids = [];

      if (audience == 'consumers' || audience == 'all') {
        Query<Map<String, dynamic>> q = _firestore.collection('users').where('role', isEqualTo: 'consumer');
        if (district != null && district.isNotEmpty) {
          q = q.where('district', isEqualTo: district);
        }
        final snap = await q.get();
        recipientUids.addAll(snap.docs.map((d) => d.id));
      }

      if (audience == 'providers' || audience == 'all') {
        Query<Map<String, dynamic>> q = _firestore.collection('providers');
        if (district != null && district.isNotEmpty) {
          q = q.where('district', isEqualTo: district);
        }
        final snap = await q.get();
        recipientUids.addAll(snap.docs.map((d) => d.id));
      }

      for (var i = 0; i < recipientUids.length; i += 400) {
        final chunk = recipientUids.sublist(i, i + 400 > recipientUids.length ? recipientUids.length : i + 400);
        final batch = _firestore.batch();
        for (final uid in chunk) {
          final ref = _firestore.collection('notifications').doc();
          batch.set(ref, {
            'recipientUid': uid,
            'type': 'broadcast',
            'title': title,
            'body': body,
            'data': {'audience': audience, if (district != null) 'district': district},
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }

      await _firestore.collection('broadcasts').add({
        'title': title,
        'body': body,
        'audience': audience,
        'district': district,
        'recipientCount': recipientUids.length,
        'sentByAdminUid': _adminUid,
        'sentAt': FieldValue.serverTimestamp(),
      });

      await _writeAuditLog(
        action: 'send_broadcast',
        targetType: 'broadcast',
        targetId: audience,
        metadata: {'title': title, 'recipientCount': recipientUids.length, 'district': district},
      );

      return recipientUids.length;
    } on FirebaseException catch (_) {
      throw const AuthException('Could not send this broadcast. Please try again.');
    }
  }

  Stream<List<Map<String, dynamic>>> broadcastHistoryStream() {
    return _firestore
        .collection('broadcasts')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  // ---------------------------------------------------------------
  // AUDIT LOG
  // ---------------------------------------------------------------

  Stream<List<AuditLogEntry>> auditLogStream({int limit = 200}) {
    return _firestore
        .collection('audit_logs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AuditLogEntry.fromMap(d.id, d.data())).toList());
  }

  // ---------------------------------------------------------------
  // SUPPLY VS DEMAND ANALYTICS
  // ---------------------------------------------------------------

  /// Aggregates recent search activity (logged by MatchingService) against
  /// current provider availability, grouped by category+district, so admins
  /// can see where demand is outstripping supply. Kept intentionally simple
  /// (client-side aggregation over recent logs) rather than a server-side
  /// rollup, since this is a small-marketplace admin tool, not a data
  /// warehouse.
  Future<List<Map<String, dynamic>>> supplyDemandSummary({int lookbackDays = 30}) async {
    final since = DateTime.now().subtract(Duration(days: lookbackDays));

    final searchSnap = await _firestore
        .collection('search_logs')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(since))
        .get();

    final Map<String, int> searchCounts = {};
    for (final doc in searchSnap.docs) {
      final data = doc.data();
      final key = '${data['service'] ?? 'unknown'}|${data['district'] ?? 'unknown'}';
      searchCounts[key] = (searchCounts[key] ?? 0) + 1;
    }

    final providersSnap = await _firestore.collection('providers').where('available', isEqualTo: true).get();
    final Map<String, int> supplyCounts = {};
    for (final doc in providersSnap.docs) {
      final data = doc.data();
      final key = '${data['businessCategory'] ?? 'unknown'}|${data['district'] ?? 'unknown'}';
      supplyCounts[key] = (supplyCounts[key] ?? 0) + 1;
    }

    final allKeys = {...searchCounts.keys, ...supplyCounts.keys};
    final rows = allKeys.map((key) {
      final parts = key.split('|');
      final demand = searchCounts[key] ?? 0;
      final supply = supplyCounts[key] ?? 0;
      return {
        'category': parts[0],
        'district': parts[1],
        'searchVolume': demand,
        'availableProviders': supply,
        'gapScore': demand - (supply * 3), // simple heuristic, tune as needed
      };
    }).toList();

    rows.sort((a, b) => (b['gapScore'] as int).compareTo(a['gapScore'] as int));
    return rows;
  }

  // ---------------------------------------------------------------
  // SUPER ADMIN — ADMIN MANAGEMENT
  // ---------------------------------------------------------------
  // These methods are only callable from SuperAdminTab. Firestore rules
  // enforce that only super_admin can write to admin_settings and only
  // a super_admin can elevate another user's role to 'admin'.

  /// Live stream of all users whose role is 'admin' (not super_admin).
  Stream<List<Map<String, dynamic>>> adminsStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'uid': d.id}).toList());
  }

  /// Returns the current max-admin quota from admin_settings.
  /// Defaults to 5 if the document doesn't exist yet.
  Future<int> getAdminQuota() async {
    try {
      final doc = await _firestore.collection('admin_settings').doc('quota').get();
      if (!doc.exists) return 5;
      return (doc.data()?['maxAdmins'] as int?) ?? 5;
    } on FirebaseException catch (_) {
      return 5;
    }
  }

  /// Updates the max-admin quota. Super admin only.
  Future<void> setAdminQuota(int newMax) async {
    try {
      await _firestore.collection('admin_settings').doc('quota').set({'maxAdmins': newMax});
      await _writeAuditLog(
        action: 'set_admin_quota',
        targetType: 'admin_settings',
        targetId: 'quota',
        metadata: {'maxAdmins': newMax},
      );
    } on FirebaseException catch (_) {
      throw const AuthException('Could not update the admin quota. Please try again.');
    }
  }

  /// Promotes a regular user to the 'admin' role, respecting the quota.
  /// The calling user must be a super_admin (enforced by Firestore rules).
  Future<void> promoteToAdmin(String uid) async {
    try {
      // Enforce quota before writing
      final currentAdminsSnap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      final quota = await getAdminQuota();
      if (currentAdminsSnap.docs.length >= quota) {
        throw AuthException(
          'Admin quota reached ($quota). Increase the quota before promoting another user.',
        );
      }

      await _firestore.collection('users').doc(uid).update({'role': 'admin'});
      await _writeAuditLog(
        action: 'promote_to_admin',
        targetType: 'user',
        targetId: uid,
      );
    } on AuthException {
      rethrow;
    } on FirebaseException catch (_) {
      throw const AuthException('Could not promote this user. Please try again.');
    }
  }

  /// Removes admin role from a user, reverting them to 'consumer'.
  /// Cannot be used to demote a super_admin.
  Future<void> demoteAdmin(String uid) async {
    try {
      // Safety: fetch current role — refuse to demote a super_admin
      final doc = await _firestore.collection('users').doc(uid).get();
      final role = (doc.data()?['role'] as String?) ?? '';
      if (role == 'super_admin') {
        throw const AuthException('Cannot demote a super admin.');
      }
      await _firestore.collection('users').doc(uid).update({'role': 'consumer'});
      await _writeAuditLog(
        action: 'demote_admin',
        targetType: 'user',
        targetId: uid,
      );
    } on AuthException {
      rethrow;
    } on FirebaseException catch (_) {
      throw const AuthException('Could not demote this admin. Please try again.');
    }
  }

  /// Suspends an admin account (blocks login via the suspended-check in
  /// LoginScreen). Super admin cannot suspend themselves.
  Future<void> suspendAdmin({
    required String uid,
    required String reason,
    required String currentSuperAdminUid,
  }) async {
    if (uid == currentSuperAdminUid) {
      throw const AuthException('You cannot suspend your own account.');
    }
    try {
      await _firestore.collection('users').doc(uid).update({
        'accountStatus': 'suspended',
        'suspendedAt': FieldValue.serverTimestamp(),
        'suspensionReason': reason,
      });
      await _writeAuditLog(
        action: 'suspend_admin',
        targetType: 'user',
        targetId: uid,
        reason: reason,
      );
    } on AuthException {
      rethrow;
    } on FirebaseException catch (_) {
      throw const AuthException('Could not suspend this admin. Please try again.');
    }
  }

  /// Reinstates a suspended admin account.
  Future<void> reinstateAdmin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'accountStatus': 'active',
        'suspensionReason': FieldValue.delete(),
      });
      await _writeAuditLog(
        action: 'reinstate_admin',
        targetType: 'user',
        targetId: uid,
      );
    } on FirebaseException catch (_) {
      throw const AuthException('Could not reinstate this admin. Please try again.');
    }
  }
}
