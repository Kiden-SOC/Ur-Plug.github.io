import 'package:flutter/foundation.dart';

import '../models/provider_profile.dart';
import '../services/api_service.dart';

/// App-wide state for the logged-in provider (business) account.
///
/// Built on ChangeNotifier + the `provider` package so any widget can
/// watch profile, service listings, job requests, ratings and chat
/// threads without prop-drilling.
class ProviderProfileController extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  String _email = '';
  ProviderProfile _profile = const ProviderProfile();
  List<ServiceListing> _services = [];
  List<JobRequest> _jobRequests = [];
  List<ProviderRating> _ratings = [];
  List<ChatThread> _threads = [];
  bool _loading = false;

  String get email => _email;
  ProviderProfile get profile => _profile;
  List<ServiceListing> get services => List.unmodifiable(_services);
  List<JobRequest> get jobRequests => List.unmodifiable(_jobRequests);
  List<ProviderRating> get ratings => List.unmodifiable(_ratings);
  List<ChatThread> get threads => List.unmodifiable(_threads);
  bool get loading => _loading;

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

  /// Called right after a successful business login.
  /// Loads any saved profile; if none exists the UI routes to onboarding.
  Future<void> initializeSession(String email) async {
    _email = email;
    _loading = true;
    notifyListeners();

    final saved = await _api.fetchProviderProfile(email);
    if (saved != null) {
      _profile = saved;
    }

    _loading = false;
    notifyListeners();
  }

  /// Persists the profile captured by the onboarding flow.
  Future<bool> completeOnboarding(ProviderProfile profile) async {
    final finished = profile.copyWith(onboardingComplete: true);
    final ok = await _api.saveProviderProfile(_email, finished);
    if (ok) {
      _profile = finished;
      notifyListeners();
    }
    return ok;
  }

  /// Edit-profile updates after onboarding.
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

  // ------------------------------------------------------------
  // PROFILE PHOTO
  // ------------------------------------------------------------

  /// Sets/replaces the provider's profile photo. Persists immediately and
  /// notifies listeners so every screen showing the avatar updates at once.
  Future<bool> setProfilePhoto(String localPath) async {
    final updated = _profile.copyWith(profilePhotoPath: localPath);
    final ok = await _api.saveProviderProfile(_email, updated);
    if (ok) {
      _profile = updated;
      notifyListeners();
    }
    return ok;
  }

  // ------------------------------------------------------------
  // BUSINESS / WORK PHOTOS (visible to customers)
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // LOCATION (entered manually by the provider, editable afterwards)
  // ------------------------------------------------------------

  /// Updates the saved location. Because every screen reads location off
  /// this single [_profile] instance, an update here is reflected
  /// everywhere in the app automatically the moment it is saved.
  Future<bool> updateLocation({
    double? latitude,
    double? longitude,
    required String district,
    required String landmarkDescription,
  }) async {
    final updated = _profile.copyWith(
      latitude: latitude,
      longitude: longitude,
      district: district,
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

    final results = await Future.wait([
      _api.fetchJobRequests(),
      _api.fetchRatings(),
      _api.fetchChatThreads(),
    ]);

    _jobRequests = results[0] as List<JobRequest>;
    _ratings = results[1] as List<ProviderRating>;
    _threads = results[2] as List<ChatThread>;
    _loading = false;
    notifyListeners();
  }

  void setJobStatus(String jobId, JobStatus status) {
    for (final job in _jobRequests) {
      if (job.id == jobId) {
        job.status = status;
      }
    }
    notifyListeners();
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

  /// Clears everything on logout.
  void clearSession() {
    _email = '';
    _profile = const ProviderProfile();
    _services = [];
    _jobRequests = [];
    _ratings = [];
    _threads = [];
    notifyListeners();
  }
}