import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../state/customer_profile_controller.dart';
import 'customer_chat_screen.dart';
import 'package:ur_plug/services/auth_service.dart';

class ProviderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> provider;
  const ProviderDetailScreen({super.key, required this.provider});

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  static const Color brandPrimary = Color(0xFF005F73);
  static const Color brandSecondary = Color(0xFF0A9396);
  static const Color screenBackground = Color(0xFFE0F2F1);

  bool _checkingStatus = true;
  bool _alreadyRequested = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  Future<void> _checkExistingRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    final providerId = widget.provider['id'] ?? '';
    if (user == null || providerId.isEmpty) {
      setState(() => _checkingStatus = false);
      return;
    }

    final existing = await FirebaseFirestore.instance
        .collection('bookings')
        .where('customerUid', isEqualTo: user.uid)
        .where('providerUid', isEqualTo: providerId)
        .where('status', whereIn: ['pending', 'accepted'])
        .limit(1)
        .get();

    if (mounted) {
      setState(() {
        _alreadyRequested = existing.docs.isNotEmpty;
        _checkingStatus = false;
      });
    }
  }

  Future<void> _requestProvider() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _submitting = true);

    final currentUser = await AuthService().getCurrentUser();
    final customerName = currentUser?.fullName ?? 'Customer';

    await FirebaseFirestore.instance.collection('bookings').add({
      'customerUid': user.uid,
      'customerName': customerName,
      'providerUid': widget.provider['id'] ?? '',
      'providerName': widget.provider['name'] ?? '',
      'category': widget.provider['category'] ?? '',
      'status': 'pending',
      'reviewed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      setState(() {
        _alreadyRequested = true;
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent! The provider will respond shortly.')),
      );
    }
  }

  void _showReviewDialog(BuildContext context) {
    final commentController = TextEditingController();
    double starRating = 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Leave a Review', style: TextStyle(fontWeight: FontWeight.bold, color: brandPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < starRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setState(() => starRating = (index + 1).toDouble()),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: brandPrimary, foregroundColor: Colors.white),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                final customerProfile = context.read<CustomerProfileController>().profile;
                final providerId = widget.provider['id'] ?? '';

                await FirebaseFirestore.instance
                    .collection('providers')
                    .doc(providerId)
                    .collection('reviews')
                    .add({
                  'customerUid': user.uid,
                  'customerName': customerProfile.name.isNotEmpty ? customerProfile.name : 'Anonymous',
                  'rating': starRating,
                  'comment': commentController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review submitted!')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String providerId = widget.provider['id'] ?? '';
    final String businessName = widget.provider['name'] ?? 'Unnamed Business';
    final String tradeTitle = widget.provider['category'] ?? '';
    final String district = widget.provider['district'] ?? '';
    final String town = widget.provider['town'] ?? '';
    final String rating = widget.provider['rating'] ?? '0.0';
    final String completedJobs = widget.provider['jobs'] ?? '0';

    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: const Text('Provider Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: brandPrimary.withValues(alpha: 0.1),
                    child: const Icon(Icons.storefront, size: 45, color: brandPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(businessName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: brandPrimary), textAlign: TextAlign.center),
                  if (tradeTitle.isNotEmpty)
                    Text(tradeTitle, style: const TextStyle(fontSize: 15, color: brandSecondary, fontWeight: FontWeight.w600)),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricItem(Icons.task_alt, 'Completed Jobs', completedJobs),
                      _buildMetricItem(Icons.star, 'Rating', rating),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (district.isNotEmpty || town.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.near_me, color: brandSecondary, size: 20),
                        SizedBox(width: 8),
                        Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandPrimary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('$town, $district', style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (_checkingStatus || _alreadyRequested || _submitting) ? null : _requestProvider,
                      icon: _submitting
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : Icon(_alreadyRequested ? Icons.check_circle_outline : Icons.handshake_outlined, size: 20),
                      label: Text(
                        _alreadyRequested ? 'Requested' : 'Request Provider',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _alreadyRequested ? Colors.grey.shade400 : brandSecondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChatScreen(providerUid: providerId, providerName: businessName)),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      label: const Text('Message', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showReviewDialog(context),
                icon: const Icon(Icons.rate_review_outlined, size: 18, color: brandPrimary),
                label: const Text('Leave a Review', style: TextStyle(color: brandPrimary, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: brandPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 28),

            const Text('Client Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brandPrimary)),
            const SizedBox(height: 12),

            if (providerId.isEmpty)
              const Text('Reviews unavailable.', style: TextStyle(color: Colors.grey, fontSize: 13))
            else
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('providers')
                    .doc(providerId)
                    .collection('reviews')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator(color: brandPrimary)),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No reviews yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    );
                  }
                  final reviews = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final data = reviews[index].data() as Map<String, dynamic>;
                      return _buildReviewCard(
                        clientName: data['customerName'] ?? 'Anonymous',
                        reviewText: data['comment'] ?? '',
                        starRating: (data['rating'] ?? 0).toString(),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: brandSecondary, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandPrimary)),
      ],
    );
  }

  Widget _buildReviewCard({required String clientName, required String reviewText, required String starRating}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: brandPrimary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person_outline, size: 16, color: brandPrimary),
                ),
                const SizedBox(width: 10),
                Text(clientName, style: const TextStyle(fontWeight: FontWeight.bold, color: brandPrimary, fontSize: 13)),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(starRating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
            if (reviewText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(reviewText, style: const TextStyle(color: Colors.black87, fontSize: 12.5, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}