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
    // No backend endpoint connected yet — returns an empty list so every
    // screen that reads this (Pending Jobs, Unfinished Jobs, Job History)
    // shows its proper empty state instead of fabricated demo entries.
    // Once the real endpoint is live, replace this with an HTTP call
    // that returns the provider's actual job requests, e.g.:
    //
    // final response = await http
    //     .get(Uri.parse('$baseUrl/providers/jobs'))
    //     .timeout(_timeout);
    // final List data = json.decode(response.body);
    // return data.map((e) => JobRequest.fromJson(e)).toList();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return [];
  }

  // ---------------------------------------------------------------
  // RATINGS RECEIVED
  // ---------------------------------------------------------------

  Future<List<ProviderRating>> fetchRatings() async {
    // No backend endpoint connected yet — returns an empty list so the
    // Ratings & Reviews screen shows its empty state instead of
    // fabricated demo reviews. Swap in the real GET call once the
    // ratings endpoint is live.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [];
  }

  // ---------------------------------------------------------------
  // TOP / LOYAL CUSTOMERS
  // ---------------------------------------------------------------

  Future<List<TopCustomer>> fetchTopCustomers() async {
    // No backend endpoint connected yet — returns an empty list so the
    // Top Customers screen shows its empty state instead of fabricated
    // demo names. Swap in the real GET call once that endpoint is live.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [];
  }

  // ---------------------------------------------------------------
  // MESSAGES / CHAT THREADS
  // ---------------------------------------------------------------

  Future<List<ChatThread>> fetchChatThreads() async {
    // No backend endpoint connected yet — returns an empty list so the
    // Messages screen shows its empty state instead of fabricated demo
    // conversations. Swap in the real GET call once messaging is live.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const [];
  }
}