import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String contact;
  final String role;
  final String district;
  final String town;
  final DateTime createdAt;
  final bool profileComplete;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.contact,
    required this.role,
    required this.district,
    required this.town,
    required this.createdAt,
    required this.profileComplete,
});

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'contact': contact,
      'role': role,
      'district': district,
      'town': town,
      'createdAt': createdAt,
      'profileCompleted': profileComplete,
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      fullName:map['fullName'] ?? '',
      email: map['email'] ?? '',
      contact: map['contact'] ?? '',
      role: map['role'] ?? 'consumer',
      district: map['district'] ?? '',
      town: map['town'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      profileComplete: map['profileComplete'] ?? false,
    );
  }

}