import 'package:flutter/material.dart';

import '../models/review.dart';
import '../services/review_service.dart';
import '../widgets/review_card.dart';
import '../widgets/star_rating.dart';

class ReviewsListScreen extends StatefulWidget {
  final String plugId;
  final String plugName;
  final String authToken;

  const ReviewsListScreen({
    super.key,
    required this.plugId,
    required this.plugName,
    required this.authToken,
  });

  @override
  State<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends State<ReviewsListScreen> {
  late final ReviewService _service;
  late Future<List<Review>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _service = ReviewService(authToken: widget.authToken);
    _reviewsFuture = _service.fetchReviewsFor(widget.plugId);
  }

  double _average(List<Review> reviews) {
    if (reviews.isEmpty) return 0;
    return reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: Text('${widget.plugName}\'s reviews')),
      body: FutureBuilder<List<Review>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reviews = snapshot.data!;
          if (reviews.isEmpty) {
            return const Center(
              child: Text('No reviews yet.', style: TextStyle(color: Colors.black54)),
            );
          }
          final avg = _average(reviews);
          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    StarRating(rating: avg.round(), size: 22),
                    const SizedBox(height: 4),
                    Text(
                      '${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: reviews.length,
                  itemBuilder: (context, i) => ReviewCard(review: reviews[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
