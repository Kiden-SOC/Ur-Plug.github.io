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
  // The bio data is hidden inside this provider Map.
  // We will display it in the build method using: widget.provider['bio']
  // (or 'description'/'about' depending on your Firestore key)
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
  bool _checkingReviewEligibility = false;

  // Added variables for the lecturer's pop-up requirement
  final _dialogFormKey = GlobalKey<FormState>();
  // Split into Start Date and End Date to cover the full booking range
  DateTime? _bookingStartDate;
  DateTime? _bookingEndDate;
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

  // Updated to receive location, timing (start/end date range), and job parameters
  Future<void> _requestProvider({
    required String district,
    required String town,
    required String startDate,
    required String endDate,
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
      'startDate': startDate,
      'endDate': endDate,
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

  // The modal builder that requests Where, When (start/end date + time), and What info
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
                      // Start Date + End Date row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _bookingStartDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 90)),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    _bookingStartDate = picked;
                                    // Clear an end date that's now before the new start date
                                    if (_bookingEndDate != null && _bookingEndDate!.isBefore(_bookingStartDate!)) {
                                      _bookingEndDate = null;
                                    }
                                  });
                                }
                              },
                              icon: const Icon(Icons.calendar_month, size: 16, color: brandPrimary),
                              label: Text(
                                _bookingStartDate == null ? 'Start Date' : DateFormat('yyyy-MM-dd').format(_bookingStartDate!),
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _bookingEndDate ?? _bookingStartDate ?? DateTime.now(),
                                  firstDate: _bookingStartDate ?? DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 90)),
                                );
                                if (picked != null) setDialogState(() => _bookingEndDate = picked);
                              },
                              icon: const Icon(Icons.calendar_month, size: 16, color: brandPrimary),
                              label: Text(
                                _bookingEndDate == null ? 'End Date' : DateFormat('yyyy-MM-dd').format(_bookingEndDate!),
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Time picker on its own row below the date range
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (picked != null) setDialogState(() => _bookingTime = picked);
                        },
                        icon: const Icon(Icons.access_time, size: 16, color: brandPrimary),
                        label: Text(
                          _bookingTime == null ? 'Time' : _bookingTime!.format(context),
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
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
                      if (_bookingStartDate == null || _bookingEndDate == null || _bookingTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select Start Date, End Date, and Time!'), backgroundColor: Colors.orange),
                        );
                        return;
                      }
                      final String targetDistrict = _dialogDistrictController.text.trim();
                      final String targetTown = _dialogTownController.text.trim();
                      final String finalStartDate = DateFormat('yyyy-MM-dd').format(_bookingStartDate!);
                      final String finalEndDate = DateFormat('yyyy-MM-dd').format(_bookingEndDate!);
                      final String finalTime = _bookingTime!.format(context);
                      final String issueDetails = _dialogDetailsController.text.trim();

                      Navigator.of(dialogContext).pop();

                      _requestProvider(
                        district: targetDistrict,
                        town: targetTown,
                        startDate: finalStartDate,
                        endDate: finalEndDate,
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

  /// Looks for a completed, not-yet-reviewed booking between the current
  /// customer and this provider. Returns the booking doc ID, or null if
  /// no eligible booking exists.
  Future<String?> _findEligibleBookingId() async {
    final user = FirebaseAuth.instance.currentUser;
    final providerId = widget.provider['id'] ?? '';
    if (user == null || providerId.isEmpty) return null;

    final snap = await FirebaseFirestore.instance
        .collection('bookings')
        .where('customerUid', isEqualTo: user.uid)
        .where('providerUid', isEqualTo: providerId)
        .where('status', isEqualTo: 'completed')
        .where('reviewed', isEqualTo: false)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Future<void> _onLeaveReviewPressed() async {
    setState(() => _checkingReviewEligibility = true);
    final jobId = await _findEligibleBookingId();
    if (!mounted) return;
    setState(() => _checkingReviewEligibility = false);

    if (jobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only review a provider after a completed job with them.'),
        ),
      );
      return;
    }

    _showReviewDialog(context, jobId);
  }

  void _showReviewDialog(BuildContext context, String jobId) {
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
                if (providerId.isEmpty) return;

                final providerRef =
                FirebaseFirestore.instance.collection('providers').doc(providerId);
                final reviewRef = providerRef.collection('reviews').doc();
                final jobRef = FirebaseFirestore.instance.collection('bookings').doc(jobId);

                try {
                  await FirebaseFirestore.instance.runTransaction((tx) async {
                    final providerSnap = await tx.get(providerRef);
                    final data = providerSnap.data() ?? {};
                    final currentCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
                    final currentAvg = (data['rating'] as num?)?.toDouble() ?? 0.0;

                    final newCount = currentCount + 1;
                    final newAvg = ((currentAvg * currentCount) + starRating) / newCount;

                    tx.set(reviewRef, {
                      'jobId': jobId,
                      'customerUid': user.uid,
                      'customerName': customerProfile.name.isNotEmpty
                          ? customerProfile.name
                          : 'Anonymous',
                      'rating': starRating,
                      'comment': commentController.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    tx.update(providerRef, {
                      'rating': newAvg,
                      'reviewCount': newCount,
                    });

                    tx.update(jobRef, {'reviewed': true});
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review submitted!')),
                    );
                  }
                } catch (e) {
                  debugPrint('Review submit error: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Couldn't submit review. Try again.")),
                    );
                  }
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

    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: const Text('Provider Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: providerId.isNotEmpty
            ? FirebaseFirestore.instance.collection('providers').doc(providerId).snapshots()
            : null,
        builder: (context, snapshot) {
          // Falls back to whatever the list screen already had (id/name/
          // category at minimum) while the live doc is still loading, then
          // switches to the live Firestore data — which is what keeps the
          // photo, bio and services current the moment the provider changes
          // them, with no need to leave and reopen this screen.
          final Map<String, dynamic> data =
              (snapshot.data?.data() as Map<String, dynamic>?) ?? widget.provider;

          final String businessName = _pick(data, ['businessName', 'name'], 'Unnamed Business');
          final String tradeTitle = _pick(data, ['businessCategory', 'category']);
          final String district = _pick(data, ['district']);
          final String town = _pick(data, ['town']);
          final String rating = (data['rating'] ?? '0.0').toString();
          final String completedJobs = (data['jobs'] ?? data['completedJobs'] ?? '0').toString();
          final String profilePhotoUrl = _pick(data, ['profilePhotoUrl']);
          final List<String> workPhotos = (data['businessPhotoUrls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
              const [];

          // RETRIEVES THE BIO FIELD FROM FIRESTORE
          final String rawBio = _pick(data, ['bio']);
          final String businessBio =
          rawBio.isNotEmpty ? rawBio : 'No service description provided by this business.';

          // Years of experience the provider entered when signing up.
          final int yearsOfExperience = int.tryParse((data['yearsOfExperience'] ?? '0').toString()) ?? 0;

          return _buildBody(
            context: context,
            providerId: providerId,
            businessName: businessName,
            tradeTitle: tradeTitle,
            district: district,
            town: town,
            rating: rating,
            completedJobs: completedJobs,
            profilePhotoUrl: profilePhotoUrl,
            workPhotos: workPhotos,
            businessBio: businessBio,
            yearsOfExperience: yearsOfExperience,
          );
        },
      ),
    );
  }

  /// Reads the first non-empty value found across [keys] in [data], so the
  /// UI works whether the map came from the live Firestore doc (which uses
  /// names like `businessName`) or the fallback passed in from a list
  /// screen (which sometimes used shorter aliases like `name`).
  String _pick(Map<String, dynamic> data, List<String> keys, [String fallback = '']) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return fallback;
  }

  void _showWorkPhotosSheet(BuildContext context, String providerId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StreamBuilder<DocumentSnapshot>(
              // A separate live listener so the gallery keeps updating even
              // while the sheet is open, in case the provider adds photos
              // from another device at that exact moment.
              stream: FirebaseFirestore.instance.collection('providers').doc(providerId).snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final photos = (data?['businessPhotoUrls'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.photo_library_outlined, color: brandPrimary),
                          const SizedBox(width: 8),
                          Text('Work photos (${photos.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandPrimary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: photos.isEmpty
                            ? const Center(
                          child: Text(
                            'This provider hasn\'t uploaded any work photos yet.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        )
                            : GridView.builder(
                          controller: scrollController,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: photos.length,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                photos[index],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: screenBackground,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                ),
                                loadingBuilder: (context, child, progress) => progress == null
                                    ? child
                                    : const Center(
                                  child: CircularProgressIndicator(color: brandPrimary, strokeWidth: 2),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required String providerId,
    required String businessName,
    required String tradeTitle,
    required String district,
    required String town,
    required String rating,
    required String completedJobs,
    required String profilePhotoUrl,
    required List<String> workPhotos,
    required String businessBio,
    required int yearsOfExperience,
  }) {
    return SingleChildScrollView(
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
                  child: profilePhotoUrl.isEmpty
                      ? const Icon(Icons.storefront, size: 45, color: brandPrimary)
                      : ClipOval(
                    child: Image.network(
                      profilePhotoUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.storefront, size: 45, color: brandPrimary),
                      loadingBuilder: (context, child, progress) => progress == null
                          ? child
                          : const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: brandPrimary),
                      ),
                    ),
                  ),
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
                    _buildMetricItem(Icons.workspace_premium, 'Experience',
                        yearsOfExperience > 0 ? '$yearsOfExperience yrs' : 'New'),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // BRAND NEW CONTAINER BLOCK THAT DISPLAYS THE BIO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: brandSecondary, size: 20),
                    SizedBox(width: 8),
                    Text('Service Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  businessBio,
                  style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SERVICES OFFERED — the service list the provider set up in
          // their Service Listings screen, streamed live from Firestore
          // so the consumer can review it before choosing this provider.
          if (providerId.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.design_services_outlined, color: brandSecondary, size: 20),
                      SizedBox(width: 8),
                      Text('Services Offered', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: brandPrimary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('providers')
                        .doc(providerId)
                        .collection('services')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator(color: brandPrimary, strokeWidth: 2)),
                        );
                      }
                      final allDocs = snapshot.data?.docs ?? [];
                      final activeDocs = allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['isActive'] ?? true;
                      }).toList();

                      if (activeDocs.isEmpty) {
                        return const Text(
                          'This provider hasn\'t published any service listings yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        );
                      }

                      return Column(
                        children: activeDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final title = (data['title'] ?? '').toString();
                          final description = (data['description'] ?? '').toString();
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: screenBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, size: 15, color: brandSecondary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: brandPrimary)),
                                    ),
                                  ],
                                ),
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(description,
                                      style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.35)),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          if (providerId.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showWorkPhotosSheet(context, providerId),
                icon: const Icon(Icons.photo_library_outlined, size: 18, color: brandPrimary),
                label: Text(
                  workPhotos.isEmpty
                      ? 'View work photos'
                      : 'View work photos (${workPhotos.length})',
                  style: const TextStyle(color: brandPrimary, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: brandPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
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
                                      Navigator.pop(context);

                                      try {
                                        // Try the phone stored in the providers collection first
                                        String phoneNumber = (widget.provider['phone'] ?? '').toString().trim();

                                        // Fallback: get the phone from the users collection
                                        if (phoneNumber.isEmpty) {
                                          final String providerUid = widget.provider['id'] ?? '';

                                          if (providerUid.isNotEmpty) {
                                            final userDoc = await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(providerUid)
                                                .get();

                                            if (userDoc.exists) {
                                              phoneNumber =
                                                  (userDoc.data()?['contact'] ?? '').toString().trim();
                                            }
                                          }
                                        }

                                        if (phoneNumber.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Provider phone number not available.'),
                                            ),
                                          );
                                          return;
                                        }

                                        final Uri phoneUri = Uri(
                                          scheme: 'tel',
                                          path: phoneNumber,
                                        );

                                        if (await canLaunchUrl(phoneUri)) {
                                          await launchUrl(phoneUri);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Phone number: $phoneNumber\n(No phone app available on this device)',
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                          ),
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
              onPressed: _checkingReviewEligibility ? null : _onLeaveReviewPressed,
              icon: _checkingReviewEligibility
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: brandPrimary),
              )
                  : const Icon(Icons.rate_review_outlined, size: 18, color: brandPrimary),
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
                    final reviewRatingValue = (data['rating'] ?? 5.0).toString();

                    return _buildReviewCard(
                      clientName: name,
                      reviewText: comment,
                      starRating: reviewRatingValue,
                    );
                  },
                );
              },
            ),
        ],
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