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
    try {
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
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  Future<User?> login({required String email, required String password}) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      return result.user;
    } on FirebaseAuthException catch(e) {
      throw _mapAuthError(e);
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
String _mapAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return 'An account already exists with that email.';
    case 'invalid-email':
      return 'That email address looks invalid.';
    case 'weak-password':
      return 'Password should be at least 6 characters.';
    case 'user-not-found':
      return 'No account found with that email.';
    case 'wrong-password':
      return 'Incorrect password.';
    case 'too-many-requests':
      return 'Too many attempts. Try again later.';
    default:
      return 'Something went wrong. Please try again.';
  }
}
