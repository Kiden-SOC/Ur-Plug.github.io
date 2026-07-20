import 'package:flutter/material.dart';

import '../services/review_service.dart';
import '../widgets/star_rating.dart';

class LeaveReviewScreen extends StatefulWidget {
  final String jobId;
  final String plugName;
  final String authToken;

  const LeaveReviewScreen({
    super.key,
    required this.jobId,
    required this.plugName,
    required this.authToken,
  });

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  late final ReviewService _service;
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _service = ReviewService(authToken: widget.authToken);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap a star to rate before submitting.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _service.submitReview(
        jobId: widget.jobId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review posted. Thanks!')),
      );
    } on ReviewSubmitException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn\'t submit right now. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Review ${widget.plugName}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How was the job?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Center(
              child: StarRating(
                rating: _rating,
                size: 40,
                onChanged: (r) => setState(() => _rating = r),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Say something about the plug\'s work (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
