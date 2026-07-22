import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/provider_profile.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'signup_session.dart';

class ProviderProfileController extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final AuthService _authService = AuthService();

  String _email = '';
  ProviderProfile _profile = const ProviderProfile();
  List<ServiceListing> _services = [];
  List<JobRequest> _jobRequests = [];
  List<ProviderRating> _ratings = [];
  List<ChatThread> _threads = [];
  List<TopCustomer> _topCustomers = [];
  bool _loading = false;

  String get email => _email;
  ProviderProfile get profile => _profile;
  List<ServiceListing> get services => List.unmodifiable(_services);
  List<JobRequest> get jobRequests => List.unmodifiable(_jobRequests);
  List<ProviderRating> get ratings => List.unmodifiable(_ratings);
  List<ChatThread> get threads => List.unmodifiable(_threads);
  List<TopCustomer> get topCustomers => List.unmodifiable(_topCustomers);
  bool get loading => _loading;

  List<JobRequest> get ongoingJobs =>
      _jobRequests.where((j) => j.status == JobStatus.accepted).toList();

  List<JobRequest> get jobHistory => _jobRequests
      .where((j) => j.status != JobStatus.pending)
      .toList()
      .reversed
      .toList();

  int get ongoingJobCount => ongoingJobs.length;

  bool get needsOnboarding => !_profile.onboardingComplete;

  double get averageRating {
    if (_ratings.isEmpty) return 0;
    final total = _ratings.fold<double>(0, (sum, r) => sum + r.stars);
    return total / _ratings.length;
  }

  int get pendingJobCount =>
      _jobRequests.where((j) => j.status == JobStatus.pending).length;

  int get unreadMessageCount =>
      _threads.fold<int>(0, (sum, t) => sum + t.unreadCount);

  Future<void> initializeSession(String email) async {
    _email = email;
    _loading = true;
    notifyListeners();

    final saved = await _api.fetchProviderProfile(email);
    if (saved != null) {
      _profile = saved;
    } else {
      final signup = SignupSession.instance.forEmail(email);
      if (signup != null) {
        _profile = _profile.copyWith(
          businessName: signup.businessName,
          district: signup.district,
          town: signup.town,
        );
      }
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> completeOnboarding(ProviderProfile profile) async {
    final finished = profile.copyWith(onboardingComplete: true);
    final ok = await _api.saveProviderProfile(_email, finished);
    if (ok) {
      _profile = finished;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> updateProfile(ProviderProfile profile) async {
    final ok = await _api.saveProviderProfile(_email, profile);
    if (ok) {
      _profile = profile.copyWith(onboardingComplete: true);
      notifyListeners();
    }
    return ok;
  }

  void toggleAvailability() {
    _profile = _profile.copyWith(isAvailable: !_profile.isAvailable);
    notifyListeners();
  }

  Future<bool> setProfilePhoto(String localPath) async {
    final updated = _profile.copyWith(profilePhotoPath: localPath);
    final ok = await _api.saveProviderProfile(_email, updated);
    if (ok) {
      _profile = updated;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> addBusinessPhoto(String localPath) async {
    final updated = _profile.copyWith(
      businessPhotoPaths: [..._profile.businessPhotoPaths, localPath],
    );
    final ok = await _api.saveProviderProfile(_email, updated);
    if (ok) {
      _profile = updated;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> addBusinessPhotos(List<String> localPaths) async {
    if (localPaths.isEmpty) return true;
    final updated = _profile.copyWith(
      businessPhotoPaths: [..._profile.businessPhotoPaths, ...localPaths],
    );
    final ok = await _api.saveProviderProfile(_email, updated);
    if (ok) {
      _profile = updated;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> removeBusinessPhoto(String localPath) async {
    final updated = _profile.copyWith(
      businessPhotoPaths: _profile.businessPhotoPaths
          .where((p) => p != localPath)
          .toList(),
    );
    final ok = await _api.saveProviderProfile(_email, updated);
    if (ok) {
      _profile = updated;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> updateLocation({
    double? latitude,
    double? longitude,
    required String district,
    required String town,
    required String landmarkDescription,
  }) async {
    final updated = _profile.copyWith(
      latitude: latitude,
      longitude: longitude,
      district: district,
      town: town,
      landmarkDescription: landmarkDescription,
    );
    final ok = await _api.saveProviderProfile(_email, updated);
    if (ok) {
      _profile = updated;
      notifyListeners();
    }
    return ok;
  }

  // ------------------------------------------------------------
  // DASHBOARD DATA
  // ------------------------------------------------------------

  Future<void> loadDashboardData() async {
    _loading = true;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid != null) {
        final data = await _authService.getProviderProfile(uid);
        if (data != null) {
          _profile = _profile.copyWith(
            businessName: data['businessName'] ?? '',
            tradeTitle: data['businessCategory'] ?? '',
            district: data['district'] ?? '',
            town: data['town'] ?? '',
            isAvailable: data['available'] ?? true,
          );
        }

        final bookingsSnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('providerUid', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .get();

        _jobRequests = bookingsSnapshot.docs.map((doc) {
          final b = doc.data();
          return JobRequest(
            id: doc.id,
            customerUid: b['customerUid'] ?? '',
            customerName: b['customerName'] ?? 'Customer',
            serviceNeeded: b['category'] ?? '',
            locationHint: b['town'] ?? b['district'] ?? '',
            requestedTime: _formatTimestamp(b['createdAt']),
            status: _mapStatus(b['status']),
          );
        }).toList();
      }

      final results = await Future.wait([
        _api.fetchRatings(),
        _api.fetchChatThreads(),
        _api.fetchTopCustomers(),
      ]);

      _ratings = results[0] as List<ProviderRating>;
      _threads = results[1] as List<ChatThread>;
      _topCustomers = results[2] as List<TopCustomer>;
    } catch (e) {
      debugPrint('loadDashboardData error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  JobStatus _mapStatus(String? status) {
    switch (status) {
      case 'accepted':
        return JobStatus.accepted;
      case 'declined':
        return JobStatus.declined;
      case 'completed':
        return JobStatus.completed;
      case 'pending':
      default:
        return JobStatus.pending;
    }
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      final date = ts.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return '';
  }

  /// Updates a job's status locally AND persists it to Firestore, so
  /// Accept/Decline/Complete actions from JobRequestCard actually stick.
  Future<void> setJobStatus(String jobId, JobStatus status) async {
    for (final job in _jobRequests) {
      if (job.id == jobId) {
        job.status = status;
      }
    }
    notifyListeners();

    final statusString = status.toString().split('.').last;
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(jobId)
        .update({'status': statusString});

    if (status == JobStatus.completed) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('providers')
            .doc(uid)
            .update({'completedJobs': FieldValue.increment(1)});
      }
    }
  }

  // ------------------------------------------------------------
  // SERVICE LISTINGS
  // ------------------------------------------------------------

  void addService(String title, String description) {
    _services.add(ServiceListing(
      id: 'svc-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
    ));
    notifyListeners();
  }

  void updateService(String id, {String? title, String? description}) {
    _services = _services
        .map((s) =>
    s.id == id ? s.copyWith(title: title, description: description) : s)
        .toList();
    notifyListeners();
  }

  void toggleServiceActive(String id) {
    _services = _services
        .map((s) => s.id == id ? s.copyWith(isActive: !s.isActive) : s)
        .toList();
    notifyListeners();
  }

  void removeService(String id) {
    _services.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void markThreadRead(String threadId) {
    _threads = _threads
        .map((t) => t.id == threadId
        ? ChatThread(
      id: t.id,
      customerName: t.customerName,
      lastMessage: t.lastMessage,
      time: t.time,
      unreadCount: 0,
    )
        : t)
        .toList();
    notifyListeners();
  }

  void clearSession() {
    _email = '';
    _profile = const ProviderProfile();
    _services = [];
    _jobRequests = [];
    _ratings = [];
    _threads = [];
    _topCustomers = [];
    notifyListeners();
  }
}