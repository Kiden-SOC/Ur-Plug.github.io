import 'package:flutter/material.dart';
import '../models/customer_profile.dart';

class CustomerProfileController extends ChangeNotifier {
  // Configured with your requested dummy baseline data
  CustomerProfile _profile = CustomerProfile(
    id: 'cust_789',
    name: 'Acen Sharon',
    phone: '+256 701 234567',
    location: 'Kirinya, Bweyogerere',
    profilePhotoPath: '',
  );

  CustomerProfile get profile => _profile;

  /// Simulates saving the new image path to your database/state layer
  Future<bool> setProfilePhoto(String localPath) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _profile = _profile.copyWith(profilePhotoPath: localPath);
      notifyListeners(); // Hot-updates your UI immediately
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
