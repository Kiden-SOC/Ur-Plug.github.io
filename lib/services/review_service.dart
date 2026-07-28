import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/review.dart';

class ReviewService {
  final String authToken; // kept for constructor compatibility, unused now

  ReviewService({required this.authToken});

  Future<ReviewEligibility> checkEligibility(String jobId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return ReviewEligibility(eligible: false, reason: 'not_a_participant');
    }

    final jobSnap = await FirebaseFirestore.instance.collection('bookings').doc(jobId).get();
    if (!jobSnap.exists) {
      return ReviewEligibility(eligible: false, reason: 'not_a_participant');
    }
    final job = jobSnap.data()!;

    if (job['customerUid'] != uid) {
      return ReviewEligibility(eligible: false, reason: 'not_a_participant');
    }
    if (job['status'] != 'completed') {
      return ReviewEligibility(eligible: false, reason: 'job_not_confirmed');
    }

    final existing = await FirebaseFirestore.instance
        .collection('providers')
        .doc(job['providerUid'])
        .collection('reviews')
        .where('jobId', isEqualTo: jobId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return ReviewEligibility(eligible: false, reason: 'already_reviewed');
    }

    return ReviewEligibility(eligible: true);
  }

  Future<List<Review>> fetchReviewsFor(String revieweeId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('providers')
        .doc(revieweeId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Review(
        id: doc.id,
        jobId: data['jobId'] ?? '',
        reviewerId: data['reviewerId'] ?? '',
        reviewerName: data['reviewerName'] ?? '',
        revieweeId: revieweeId,
        revieweeName: data['revieweeName'] ?? '',
        rating: (data['rating'] as num?)?.toInt() ?? 0,
        comment: data['comment'] ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  Future<Review> submitReview({
    required String jobId,
    required int rating,
    required String comment,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ReviewSubmitException('You need to be signed in to leave a review.');
    }

    final jobRef = FirebaseFirestore.instance.collection('bookings').doc(jobId);
    final jobSnap = await jobRef.get();
    if (!jobSnap.exists) {
      throw ReviewSubmitException('Job not found.');
    }
    final job = jobSnap.data()!;
    final providerId = job['providerUid'] as String;
    final providerName = job['providerName'] ?? '';

    final providerRef = FirebaseFirestore.instance.collection('providers').doc(providerId);
    final reviewRef = providerRef.collection('reviews').doc();

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final providerSnap = await tx.get(providerRef);
        final data = providerSnap.data() ?? {};
        final currentCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
        final currentAvg = (data['rating'] as num?)?.toDouble() ?? 0.0;

        final newCount = currentCount + 1;
        final newAvg = ((currentAvg * currentCount) + rating) / newCount;

        tx.set(reviewRef, {
          'jobId': jobId,
          'reviewerId': user.uid,
          'reviewerName': user.displayName ?? '',
          'revieweeName': providerName,
          'rating': rating,
          'comment': comment,
          'createdAt': FieldValue.serverTimestamp(),
        });

        tx.update(providerRef, {
          'rating': newAvg,
          'reviewCount': newCount,
        });

        tx.update(jobRef, {'reviewed': true});
      });
    } catch (e) {
      throw ReviewSubmitException('Something went wrong submitting your review.');
    }

    return Review(
      id: reviewRef.id,
      jobId: jobId,
      reviewerId: user.uid,
      reviewerName: user.displayName ?? '',
      revieweeId: providerId,
      revieweeName: providerName,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
  }
}

class ReviewSubmitException implements Exception {
  final String message;
  ReviewSubmitException(this.message);

  @override
  String toString() => message;
}