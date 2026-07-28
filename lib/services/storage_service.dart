import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Handles uploading provider photos (profile photo + work/business photos)
/// to Firebase Storage so they get a public download URL that can be saved
/// to Firestore and loaded from any device — the provider's own and every
/// consumer's.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isRemoteUrl(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  /// Uploads a provider's profile photo and returns its download URL.
  /// If [path] is already a remote URL (already uploaded), it's returned
  /// unchanged so we don't re-upload on every save.
  Future<String?> uploadProfilePhoto(String uid, String path) async {
    if (path.isEmpty) return '';
    if (_isRemoteUrl(path)) return path;
    try {
      final ref = _storage.ref('providers/$uid/profile.jpg');
      await ref.putFile(File(path));
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Failed to upload profile photo: $e');
      return null;
    }
  }

  /// Uploads a single work/business photo and returns its download URL.
  Future<String?> uploadWorkPhoto(String uid, String path) async {
    if (path.isEmpty) return null;
    if (_isRemoteUrl(path)) return path;
    try {
      final id = DateTime.now().microsecondsSinceEpoch;
      final ref = _storage.ref('providers/$uid/work/$id.jpg');
      await ref.putFile(File(path));
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Failed to upload work photo: $e');
      return null;
    }
  }

  /// Uploads several work photos in one go, skipping any that fail rather
  /// than aborting the whole batch.
  Future<List<String>> uploadWorkPhotos(
      String uid, List<String> paths) async {
    final urls = <String>[];
    for (final path in paths) {
      final url = await uploadWorkPhoto(uid, path);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  /// Best-effort delete — failures are swallowed since the Firestore/list
  /// removal is what actually controls visibility.
  Future<void> deletePhoto(String url) async {
    if (!_isRemoteUrl(url)) return;
    try {
      await _storage.refFromURL(url).delete();
    } catch (e) {
      debugPrint('Failed to delete photo from storage: $e');
    }
  }
}
