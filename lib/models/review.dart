class Review {
  final String id;
  final String jobId;
  final String reviewerId;
  final String reviewerName;
  final String revieweeId;
  final String revieweeName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.jobId,
    required this.reviewerId,
    required this.reviewerName,
    required this.revieweeId,
    required this.revieweeName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'].toString(),
      jobId: json['job'].toString(),
      reviewerId: json['reviewer'].toString(),
      reviewerName: json['reviewer_name'] ?? '',
      revieweeId: json['reviewee'].toString(),
      revieweeName: json['reviewee_name'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Result of GET /api/reviews/eligibility/<job_id>/
class ReviewEligibility {
  final bool eligible;
  final String? reason;

  ReviewEligibility({required this.eligible, this.reason});

  factory ReviewEligibility.fromJson(Map<String, dynamic> json) {
    return ReviewEligibility(
      eligible: json['eligible'] == true,
      reason: json['reason'],
    );
  }

  /// Human-readable copy for each reason the backend can return.
  String get message {
    switch (reason) {
      case 'job_not_confirmed':
        return 'This job hasn\'t been confirmed yet.';
      case 'already_reviewed':
        return 'You\'ve already reviewed this job.';
      case 'not_a_participant':
        return 'You weren\'t part of this job.';
      default:
        return 'You can leave a review for this job.';
    }
  }
}
