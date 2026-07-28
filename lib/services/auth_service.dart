import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/app_exceptions.dart';

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

      final createdUser = credential.user;
      if (createdUser == null) {
        throw const AuthException(
            'Account creation did not complete. Please try again.');
      }
      String uid = createdUser.uid;

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
          'businessCategoryLower': (businessCategory ?? '').toLowerCase(),
          'businessEmailAddress' : email,
          'phone': contact,
          'district': district,
          'districtLower': district.toLowerCase(),
          'town': town,
          'townLower': town.toLowerCase(),
          'rating': 0,
          'completedJobs': 0,
          'available': true,
          'verificationStatus': 'unverified',
          'createdAt': DateTime.now(),
        });
      }
      return newUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } on FirebaseException catch (_) {
      throw const AuthException(
          'Your account was created but saving your profile failed. Please try logging in, or contact support if the problem continues.');
    }
  }

  Future<User?> login({required String email, required String password}) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // fetching a single user's profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(uid, doc.data() as Map<String, dynamic>);
    } on FirebaseException catch (_) {
      throw const AuthException('Could not load your profile. Check your connection and try again.');
    }
  }

  // update a user's own profile fields
  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? contact,
    String? district,
    String? town,
  }) async {
    Map<String, dynamic> updates = {};
    if (fullName != null) updates['fullName'] = fullName;
    if (contact != null) updates['contact'] = contact;
    if (district != null) updates['district'] = district;
    if (town != null) updates['town'] = town;

    if (updates.isEmpty) return;

    try {
      await _firestore.collection('users').doc(uid).update(updates);
    } on FirebaseException catch (_) {
      throw const AuthException('Could not save your changes. Please try again.');
    }
  }

  /// Defense-in-depth admin check. Screens that gate admin-only content
  /// should call this rather than trusting a role value cached at login
  /// time, so a role downgrade/suspension takes effect immediately.
  ///
  /// Accepts both 'admin' and 'super_admin' roles.
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      final role = data['role'] as String? ?? '';
      return role == 'admin' || role == 'super_admin';
    } on FirebaseException catch (_) {
      return false;
    }
  }

  /// Returns the full role string for the current user, or null if not
  /// signed in. Use this to distinguish super_admin from admin in the UI.
  Future<String?> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return data['role'] as String?;
    } on FirebaseException catch (_) {
      return null;
    }
  }

  /// Looks up a user document by email address (case-sensitive Firestore
  /// query). Returns null if no user with that email exists.
  /// Used by SuperAdminTab to promote a user by email.
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final snap = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return UserModel.fromMap(doc.id, doc.data());
    } on FirebaseException catch (_) {
      throw const AuthException('Could not search for that user. Check your connection and try again.');
    }
  }


  Future<Map<String, dynamic>?> getProviderProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('providers').doc(uid).get();
      if (!doc.exists) return null;
      return doc.data() as Map<String, dynamic>;
    } on FirebaseException catch (_) {
      throw const AuthException('Could not load provider details. Check your connection and try again.');
    }
  }

  // update a provider's business fields
  Future<void> updateProviderProfile({
    required String uid,
    String? businessName,
    String? businessCategory,
    String? district,
    String? town,
    bool? available,
  }) async {
    Map<String, dynamic> updates = {};
    if (businessName != null) updates['businessName'] = businessName;
    if (businessCategory != null) {
      updates['businessCategory'] = businessCategory;
      updates['businessCategoryLower'] = businessCategory.toLowerCase();   // add this line
    }
    if (district != null) {
      updates['district'] = district;
      updates['districtLower'] = district.toLowerCase();
    }
    if (town != null) {
      updates['town'] = town;
      updates['townLower'] = town.toLowerCase();
    }
    if (available != null) updates['available'] = available;

    if (updates.isEmpty) return;

    try {
      await _firestore.collection('providers').doc(uid).update(updates);
    } on FirebaseException catch (_) {
      throw const AuthException('Could not save your business profile. Please try again.');
    }
  }

  //greet user by their name
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

      if (doc.exists) {
        return UserModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }
      return null;
    } on FirebaseException catch (_) {
      throw const AuthException('Could not load your profile. Check your connection and try again.');
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
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been suspended. Contact support if you think this is a mistake.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
