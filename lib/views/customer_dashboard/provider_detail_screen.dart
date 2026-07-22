import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 
import '../../state/customer_profile_controller.dart';
import 'customer_chat_screen.dart';
import 'package:ur_plug/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Added variables for the lecturer's pop-up requirement
  final _dialogFormKey = GlobalKey<FormState>();
  DateTime? _bookingDate;
  TimeOfDay? _bookingTime;
  final TextEditingController _dialogDistrictController = TextEditingController();
  final TextEditingController _dialogTownController = TextEditingController();
  final TextEditingController _dialogDetailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
    
    // Auto-populates district field using customer's profile location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final profile = context.read<CustomerProfileController>().profile;
        _dialogDistrictController.text = profile.location;
      }
    });
  }

  @override
  void dispose() {
    _dialogDistrictController.dispose();
    _dialogTownController.dispose();
    _dialogDetailsController.dispose();
    super.dispose();
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

  // Updated to receive location, timing, and job parameters
  Future<void> _requestProvider({
    required String district,
    required String town,
    required String date,
    required String time,
    required String details,
  }) async {
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
      'district': district,
      'town': town,
      'date': date,
      'time': time,
      'details': details,
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

  // The modal builder that requests Where, When, and What info
  void _showInstantBookingDialog() {
    final String providerName = widget.provider['name'] ?? 'Provider';
    final String providerService = widget.provider['category'] ?? 'General Service';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.bolt, color: brandPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Book $providerName', 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: brandPrimary, fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: _dialogFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SERVICE REQUESTED', style: TextStyle(fontWeight: FontWeight.bold, color: brandSecondary, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(providerService, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Divider(height: 20),

                      const Text('WHERE DO YOU NEED IT?', style: TextStyle(fontWeight: FontWeight.bold, color: brandSecondary, fontSize: 11)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dialogDistrictController,
                        decoration: InputDecoration(
                          labelText: 'District',
                          prefixIcon: const Icon(Icons.map, size: 20, color: brandPrimary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _dialogTownController,
                        decoration: InputDecoration(
                          labelText: 'Town / Specific Area',
                          prefixIcon: const Icon(Icons.location_on, size: 20, color: brandPrimary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      const Divider(height: 24),

                      const Text('WHEN DO YOU NEED IT?', style: TextStyle(fontWeight: FontWeight.bold, color: brandSecondary, fontSize: 11)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 90)),
                                );
                                if (picked != null) setDialogState(() => _bookingDate = picked);
                              },
                              icon: const Icon(Icons.calendar_month, size: 16, color: brandPrimary),
                              label: Text(
                                _bookingDate == null ? 'Date' : DateFormat('yyyy-MM-dd').format(_bookingDate!), 
                                style: const TextStyle(fontSize: 12, color: Colors.black87)
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                if (picked != null) setDialogState(() => _bookingTime = picked);
                              },
                              icon: const Icon(Icons.access_time, size: 16, color: brandPrimary),
                              label: Text(
                                _bookingTime == null ? 'Time' : _bookingTime!.format(context), 
                                style: const TextStyle(fontSize: 12, color: Colors.black87)
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      const Text('WHAT NEEDS TO BE DONE?', style: TextStyle(fontWeight: FontWeight.bold, color: brandSecondary, fontSize: 11)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dialogDetailsController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Describe your issue details here...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                                                validator: (value) => value!.isEmpty ? 'Please describe the problem' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: brandPrimary, foregroundColor: Colors.white),
                  onPressed: () {
                    if (_dialogFormKey.currentState!.validate()) {
                      if (_bookingDate == null || _bookingTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select both Date and Time!'), backgroundColor: Colors.orange),
                        );
                        return;
                      }
                      final String targetDistrict = _dialogDistrictController.text.trim();
                      final String targetTown = _dialogTownController.text.trim();
                      final String finalDate = DateFormat('yyyy-MM-dd').format(_bookingDate!);
                      final String finalTime = _bookingTime!.format(context);
                      final String issueDetails = _dialogDetailsController.text.trim();

                      Navigator.of(dialogContext).pop();
                      
                      _requestProvider(
                        district: targetDistrict,
                        town: targetTown,
                        date: finalDate,
                        time: finalTime,
                        details: issueDetails,
                      );
                    }
                  },
                  child: const Text('Request Service'),
                ),
              ],
            );
          },
        );
      },
    );
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
                      // Changed from direct upload to now showing the lecturer's pop-up form
                      onPressed: (_checkingStatus || _alreadyRequested || _submitting) ? null : _showInstantBookingDialog,
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
                        // Shows an options sheet to choose between Calling or Messaging
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) {
                            return SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Contact Provider',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandPrimary),
                                    ),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Color(0xFFE0F2F1),
                                        child: Icon(Icons.chat_bubble_outline, color: brandPrimary),
                                      ),
                                      title: const Text('Send a Message', style: TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: const Text('Chat inside the application'),
                                      onTap: () {
                                        Navigator.pop(context); // Close sheet
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => ChatScreen(providerUid: providerId, providerName: businessName)),
                                        );
                                      },
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Color(0xFFE0F2F1),
                                        child: Icon(Icons.call_outlined, color: brandSecondary),
                                      ),
                                      title: const Text('Call Provider', style: TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: const Text('Place a direct phone call'),
                                      onTap: () async {
                                        Navigator.pop(context); // Close sheet
                                        
                                        // Pulls phone dynamic variable directly from your provider map
                                        final String phoneNumber = widget.provider['phone'] ?? '';
                                        
                                        if (phoneNumber.isNotEmpty) {
                                          final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
                                          if (await canLaunchUrl(launchUri)) {
                                            await launchUrl(launchUri);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Could not launch the phone dialer.')),
                                            );
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Provider phone number not available.')),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.contact_mail_outlined, size: 20),
                      label: const Text('Contact', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                      final name = data['customerName'] ?? 'Anonymous';
                      final comment = data['comment'] ?? '';
                      final ratingValue = (data['rating'] ?? 5.0).toString();

                      return _buildReviewCard(
                        clientName: name,
                        reviewText: comment,
                        starRating: ratingValue,
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