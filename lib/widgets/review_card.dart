import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/review.dart';
import 'star_rating.dart';

class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review.reviewerName.isNotEmpty ? review.reviewerName : 'Anonymous',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                DateFormat('d MMM yyyy').format(review.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 4),
          StarRating(rating: review.rating, size: 16),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment, style: const TextStyle(fontSize: 14)),
          ],
        ],
      ),
    );
  }
}
