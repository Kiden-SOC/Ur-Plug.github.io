import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String contact,
    required String role,
    required String district,
    required String town,
    String? businessName,
    String? businessCategory,
  }) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    String uid = credential.user!.uid;

    UserModel newUser = UserModel(
        uid: uid,
        fullName: fullName,
        email: email,
        contact: contact,
        role: role,
        district: district,
        town: town,
        createdAt: DateTime.now(),
        profileComplete: true
    );

    await _firestore.collection('users').doc(uid).set(newUser.toMap());

    if (role == 'producer') {
      await _firestore.collection('providers').doc(uid).set({
        'businessName': businessName ?? '',
        'businessCategory': businessCategory ?? '',
        'rating': 0,
        'completedJobs': 0,
        'createdAt': DateTime.now(),
      });
    }
    return newUser;
  }

  Future<User?> login({required String email, required String password}) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
    );
    return result.user;
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
