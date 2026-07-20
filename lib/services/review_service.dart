import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/review.dart';
import 'chat_service.dart' show ChatConfig;

class ReviewService {
  final String authToken;

  ReviewService({required this.authToken});

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      };

  Future<ReviewEligibility> checkEligibility(String jobId) async {
    final res = await http.get(
      Uri.parse('${ChatConfig.httpBase}/api/reviews/eligibility/$jobId/'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      return ReviewEligibility(eligible: false, reason: 'error');
    }
    return ReviewEligibility.fromJson(jsonDecode(res.body));
  }

  Future<List<Review>> fetchReviewsFor(String revieweeId) async {
    final res = await http.get(
      Uri.parse('${ChatConfig.httpBase}/api/reviews/?reviewee=$revieweeId'),
      headers: _headers,
    );
    if (res.statusCode != 200) return [];
    final body = jsonDecode(res.body);
    final results = body is List ? body : (body['results'] as List? ?? []);
    return results.map((r) => Review.fromJson(r)).toList();
  }

  /// Returns the created Review on success. Throws a [ReviewSubmitException]
  /// with the backend's validation message on failure (e.g. job not
  /// confirmed, already reviewed).
  Future<Review> submitReview({
    required String jobId,
    required int rating,
    required String comment,
  }) async {
    final res = await http.post(
      Uri.parse('${ChatConfig.httpBase}/api/reviews/'),
      headers: _headers,
      body: jsonEncode({
        'job': jobId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (res.statusCode == 201) {
      return Review.fromJson(jsonDecode(res.body));
    }

    throw ReviewSubmitException(_extractError(res.body));
  }

  String _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final firstKey = decoded.keys.first;
        final val = decoded[firstKey];
        if (val is List && val.isNotEmpty) return val.first.toString();
        return val.toString();
      }
    } catch (_) {}
    return 'Something went wrong submitting your review.';
  }
}

class ReviewSubmitException implements Exception {
  final String message;
  ReviewSubmitException(this.message);

  @override
  String toString() => message;
}
