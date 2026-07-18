import 'package:flutter/material.dart';
import 'package:ur_plug/services/auth_service.dart';
import '../models/customer_profile.dart';

class CustomerProfileController extends ChangeNotifier {
  // Completely empty baseline model configuration
  CustomerProfile _profile = CustomerProfile(
    id: '',
    name: '',
    phone: '',
    location: '',
    profilePhotoPath: '',
  );

  CustomerProfile get profile => _profile;

  /// Fetches the logged-in user profile from active session dynamically
  Future<void> fetchAndSyncActiveUser() async {
    final user = await AuthService().getCurrentUser();
    if (user != null) {
      _profile = CustomerProfile(
        id: user.uid, 
        name: user.fullName, 
        // 🚀 DYNAMIC PRE-FILL: Preserve signup cache if present, else fallback safely
        phone: _profile.phone.isEmpty ? '' : _profile.phone, 
        location: _profile.location.isEmpty ? '' : _profile.location,
        profilePhotoPath: _profile.profilePhotoPath,
      );
      notifyListeners();
    }
  }

  /// Simulates saving the new image path to your database/state layer
  Future<bool> setProfilePhoto(String localPath) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _profile = _profile.copyWith(profilePhotoPath: localPath);
      notifyListeners(); 
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Updates profile text entries when the user clicks save
  void updateProfileDetails({required String name, required String phone, required String location}) {
    _profile = _profile.copyWith(name: name, phone: phone, location: location);
    notifyListeners();
  }
}