import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_thread.dart';
import '../models/provider_profile.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'signup_session.dart';
import '../models/job_request.dart';
import '../models/service_listing.dart';
import '../models/provider_rating.dart';
import '../models/top_customer.dart';
import '../services/storage_service.dart';


class ProviderProfileController extends ChangeNotifier {
  final ApiService _api = ApiService.instance;
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService.instance;

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
    final uploaded = await _uploadPendingPhotos(profile);
    final finished = uploaded.copyWith(onboardingComplete: true);
    final ok = await _api.saveProviderProfile(_email, finished);
    await _syncProfileToFirestore(finished);
    if (ok) {
      _profile = finished;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> updateProfile(ProviderProfile profile) async {
    final uploaded = await _uploadPendingPhotos(profile);
    final ok = await _api.saveProviderProfile(_email, uploaded);
    await _syncProfileToFirestore(uploaded);
    if (ok) {
      _profile = uploaded.copyWith(onboardingComplete: true);
      notifyListeners();
    }
    return ok;
  }

  /// Uploads a profile's photo and any business/work photos that are still
  /// local on-device paths (as opposed to already-uploaded URLs), so the
  /// saved profile only ever contains URLs any device can load.
  Future<ProviderProfile> _uploadPendingPhotos(ProviderProfile profile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return profile;

    String profilePhotoPath = profile.profilePhotoPath;
    if (profilePhotoPath.isNotEmpty &&
        !profilePhotoPath.startsWith('http')) {
      final url =
          await _storageService.uploadProfilePhoto(uid, profilePhotoPath);
      if (url != null) profilePhotoPath = url;
    }

    final businessPhotoPaths = <String>[];
    for (final path in profile.businessPhotoPaths) {
      if (path.startsWith('http')) {
        businessPhotoPaths.add(path);
      } else {
        final url = await _storageService.uploadWorkPhoto(uid, path);
        businessPhotoPaths.add(url ?? path);
      }
    }

    return profile.copyWith(
      profilePhotoPath: profilePhotoPath,
      businessPhotoPaths: businessPhotoPaths,
    );
  }

  /// Writes the fields customers see on the provider profile (experience,
  /// service description, profile photo and work photos) to the provider's
  /// Firestore document so they persist and are visible to consumers
  /// browsing providers, and update live for anyone already viewing them.
  Future<void> _syncProfileToFirestore(ProviderProfile profile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('providers').doc(uid).set({
        'bio': profile.bio,
        'yearsOfExperience': profile.yearsOfExperience,
        'profilePhotoUrl': profile.profilePhotoPath,
        'businessPhotoUrls': profile.businessPhotoPaths,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to sync provider profile to Firestore: $e');
    }
  }

  void toggleAvailability() {
    _profile = _profile.copyWith(isAvailable: !_profile.isAvailable);
    notifyListeners();
  }

  Future<bool> setProfilePhoto(String localPath) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    String photoUrl = localPath;
    if (uid != null) {
      final uploaded =
          await _storageService.uploadProfilePhoto(uid, localPath);
      if (uploaded == null) return false;
      photoUrl = uploaded;
    }

    final updated = _profile.copyWith(profilePhotoPath: photoUrl);
    final ok = await _api.saveProviderProfile(_email, updated);
    await _syncProfileToFirestore(updated);
    if (ok) {
      _profile = updated;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> addBusinessPhoto(String localPath) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    String photoUrl = localPath;
    if (uid != null) {
      final uploaded = await _storageService.uploadWorkPhoto(uid, localPath);
      if (uploaded == null) return false;
      photoUrl = uploaded;
    }

    final updated = _profile.copyWith(
      businessPhotoPaths: [..._profile.businessPhotoPaths, photoUrl],
    );
    final ok = await _api.saveProviderProfile(_email, updated);
    await _syncProfileToFirestore(updated);
    if (ok) {
      _profile = updated;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> addBusinessPhotos(List<String> localPaths) async {
    if (localPaths.isEmpty) return true;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final photoUrls = uid != null
        ? await _storageService.uploadWorkPhotos(uid, localPaths)
        : localPaths;
    if (photoUrls.isEmpty) return false;

    final updated = _profile.copyWith(
      businessPhotoPaths: [..._profile.businessPhotoPaths, ...photoUrls],
    );
    final ok = await _api.saveProviderProfile(_email, updated);
    await _syncProfileToFirestore(updated);
    if (ok) {
      _profile = updated;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> removeBusinessPhoto(String photoUrl) async {
    final updated = _profile.copyWith(
      businessPhotoPaths: _profile.businessPhotoPaths
          .where((p) => p != photoUrl)
          .toList(),
    );
    final ok = await _api.saveProviderProfile(_email, updated);
    await _syncProfileToFirestore(updated);
    if (ok) {
      _profile = updated;
      notifyListeners();
      unawaited(_storageService.deletePhoto(photoUrl));
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
            bio: data['bio'] ?? '',
            yearsOfExperience: data['yearsOfExperience'] ?? 0,
            profilePhotoPath: data['profilePhotoUrl'] ?? '',
            businessPhotoPaths:
                (data['businessPhotoUrls'] as List?)?.cast<String>() ??
                    const [],
          );
        }

        final servicesSnapshot = await FirebaseFirestore.instance
            .collection('providers')
            .doc(uid)
            .collection('services')
            .get();

        _services = servicesSnapshot.docs.map((doc) {
          final s = doc.data();
          return ServiceListing(
            id: doc.id,
            title: s['title'] ?? '',
            description: s['description'] ?? '',
            isActive: s['isActive'] ?? true,
          );
        }).toList();

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
            customerPhone: b['customerPhone'] ?? '',
            serviceNeeded: b['category'] ?? '',
            description: b['details'] ?? '',
            district: b['district'] ?? '',
            landmark: b['town'] ?? '',
            date: b['date'] ?? '',
            time: b['time'] ?? '',
            startDate: b['startDate'] ?? '',
            endDate: b['endDate'] ?? '',
            deadline: b['deadline'] ?? '',
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

  void addService(String title, String description) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final servicesRef = uid != null
        ? FirebaseFirestore.instance
            .collection('providers')
            .doc(uid)
            .collection('services')
        : null;
    final id = servicesRef?.doc().id ??
        'svc-${DateTime.now().millisecondsSinceEpoch}';

    _services.add(ServiceListing(
      id: id,
      title: title,
      description: description,
    ));
    notifyListeners();

    if (servicesRef != null) {
      try {
        await servicesRef.doc(id).set({
          'title': title,
          'description': description,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Failed to save service listing: $e');
      }
    }
  }

  void updateService(String id, {String? title, String? description}) async {
    _services = _services
        .map((s) =>
    s.id == id ? s.copyWith(title: title, description: description) : s)
        .toList();
    notifyListeners();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (updates.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .collection('services')
          .doc(id)
          .update(updates);
    } catch (e) {
      debugPrint('Failed to update service listing: $e');
    }
  }

  void toggleServiceActive(String id) async {
    bool? newActive;
    _services = _services.map((s) {
      if (s.id == id) {
        newActive = !s.isActive;
        return s.copyWith(isActive: newActive);
      }
      return s;
    }).toList();
    notifyListeners();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || newActive == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .collection('services')
          .doc(id)
          .update({'isActive': newActive});
    } catch (e) {
      debugPrint('Failed to update service listing status: $e');
    }
  }

  void removeService(String id) async {
    _services.removeWhere((s) => s.id == id);
    notifyListeners();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .collection('services')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Failed to delete service listing: $e');
    }
  }

  void markThreadRead(String threadId) {
    for (final t in _threads) {
      if (t.id == threadId) {
        t.unreadCount = 0;
      }
    }
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
