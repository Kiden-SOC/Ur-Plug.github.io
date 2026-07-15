import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/provider_profile.dart';

/// Central API integration layer.
///
/// All network traffic goes through this single class so that when the
/// real backend is ready you only change [baseUrl] and the endpoints —
/// none of the UI code has to change.
///
/// While the backend is under construction every call falls back to a
/// realistic local simulation so the whole app remains fully demoable
/// in FlutLab.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  /// Point this at the deployed backend when it is available.
  static const String baseUrl = 'https://api.urplug.example.com/v1';

  static const Duration _timeout = Duration(seconds: 6);

  // ---------------------------------------------------------------
  // PROVIDER PROFILE
  // ---------------------------------------------------------------

  Future<ProviderProfile?> fetchProviderProfile(String email) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/providers/profile?email=$email'))
          .timeout(_timeout);
      if (response.statusCode == 200) {
        return ProviderProfile.fromJson(json.decode(response.body));
      }
    } catch (_) {
      // Backend not reachable yet — treat as "no saved profile"
      // so the onboarding flow triggers on first login.
    }
    return null;
  }

  Future<bool> saveProviderProfile(String email, ProviderProfile profile) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/providers/profile'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, ...profile.toJson()}),
          )
          .timeout(_timeout);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      // Simulated success while the backend is offline. The profile is
      // still kept in memory by ProviderProfileController for the session.
      return true;
    }
  }

  // ---------------------------------------------------------------
  // JOB REQUESTS (simulated feed until the backend ships)
  // ---------------------------------------------------------------

  Future<List<JobRequest>> fetchJobRequests() async {
    // Realistic demo payload matching the customer-side data.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return [
      JobRequest(
        id: 'JOB-1042',
        customerName: 'Atim Grace',
        serviceNeeded: 'Fix a tripping circuit breaker in the main house',
        locationHint: 'Kirinya, near St. Peter\u2019s Church',
        requestedTime: 'Today, 3:00 PM',
      ),
      JobRequest(
        id: 'JOB-1043',
        customerName: 'Okello Mark',
        serviceNeeded: 'Install two new security lights on the compound wall',
        locationHint: 'Bweyogerere, opposite the stadium area',
        requestedTime: 'Tomorrow, 10:00 AM',
      ),
      JobRequest(
        id: 'JOB-1044',
        customerName: 'Nakyiwa Eleanor',
        serviceNeeded: 'Full house wiring inspection before tenancy handover',
        locationHint: 'Kireka, behind the market taxi stage',
        requestedTime: 'Sat, 9:00 AM',
        status: JobStatus.accepted,
      ),
    ];
  }

  // ---------------------------------------------------------------
  // RATINGS RECEIVED
  // ---------------------------------------------------------------

  Future<List<ProviderRating>> fetchRatings() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [
      ProviderRating(
        customerName: 'Atim Grace',
        stars: 5.0,
        comment:
            'Arrived perfectly on time and sorted my wiring fault immediately. Highly recommended!',
        date: '2 days ago',
      ),
      ProviderRating(
        customerName: 'Nakyiwa Eleanor',
        stars: 4.8,
        comment:
            'Fair pricing structure, prompt responses in-app, and professional behavior.',
        date: '1 week ago',
      ),
      ProviderRating(
        customerName: 'Ssenoga Brian',
        stars: 4.5,
        comment: 'Good work on the inverter setup. Cleaned up after the job too.',
        date: '3 weeks ago',
      ),
    ];
  }

  // ---------------------------------------------------------------
  // MESSAGES / CHAT THREADS
  // ---------------------------------------------------------------

  Future<List<ChatThread>> fetchChatThreads() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const [
      ChatThread(
        id: 'chat-1',
        customerName: 'Atim Grace',
        lastMessage: 'Great, see you at 3 PM then!',
        time: '10:24 AM',
        unreadCount: 2,
      ),
      ChatThread(
        id: 'chat-2',
        customerName: 'Okello Mark',
        lastMessage: 'How much do you charge for security lights?',
        time: 'Yesterday',
        unreadCount: 1,
      ),
      ChatThread(
        id: 'chat-3',
        customerName: 'Nakyiwa Eleanor',
        lastMessage: 'Thank you for the inspection report.',
        time: 'Mon',
      ),
    ];
  }
}