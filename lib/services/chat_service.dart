// lib/services/chat_service.dart
//
// Handles sending messages and tracking per-user, per-chat unread counts,
// WhatsApp-style. Depends only on cloud_firestore + firebase_auth.
//
// Firestore structure expected:
//
// chats/{chatId}
//   participants: [uid1, uid2]
//   otherUserName / participantNames: {} (optional, for display)
//   lastMessage: string
//   lastMessageTime: Timestamp
//   unreadCount: { uid1: 0, uid2: 2 }
//
// chats/{chatId}/messages/{messageId}
//   senderUid: string
//   text: string
//   createdAt: Timestamp

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  String? get currentUid => _auth.currentUser?.uid;

  /// Creates a chat doc if it doesn't already exist between the two users.
  /// Returns the chatId. Call this before the first message in a new
  /// conversation, or reuse an existing chatId if you already track one.
  Future<String> getOrCreateChat({
    required String otherUserId,
    required String otherUserName,
  }) async {
    final uid = currentUid;
    if (uid == null) throw StateError('No authenticated user');

    // Deterministic chat id so the same pair always maps to the same chat.
    final ids = [uid, otherUserId]..sort();
    final chatId = '${ids[0]}_${ids[1]}';

    final chatRef = _chats.doc(chatId);
    final snapshot = await chatRef.get();

    if (!snapshot.exists) {
      await chatRef.set({
        'participants': ids,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {ids[0]: 0, ids[1]: 0},
      });
    }

    return chatId;
  }

  /// Sends a message and increments the recipient's unread count for
  /// this chat in the same atomic batch.
  Future<void> sendMessage({
    required String chatId,
    required String recipientId,
    required String text,
  }) async {
    final uid = currentUid;
    if (uid == null) throw StateError('No authenticated user');
    if (text.trim().isEmpty) return;

    final chatRef = _chats.doc(chatId);
    final messageRef = chatRef.collection('messages').doc();
    final batch = _firestore.batch();

    batch.set(messageRef, {
      'senderUid': uid,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(chatRef, {
      'lastMessage': text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount.$recipientId': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// Call when the user opens a chat screen to clear their unread badge.
  Future<void> markChatAsRead(String chatId) async {
    final uid = currentUid;
    if (uid == null) return;

    await _chats.doc(chatId).update({
      'unreadCount.$uid': 0,
    });
  }

  /// Stream of the current user's chats, ordered by most recent message.
  Stream<QuerySnapshot<Map<String, dynamic>>> chatListStream() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();

    return _chats
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Stream of messages within a single chat, oldest first.
  Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// Total unread count across all of the current user's chats.
  /// Useful for a single bell-icon badge (e.g. in an app bar).
  Stream<int> totalUnreadStream() {
    return chatListStream().map((snapshot) {
      final uid = currentUid;
      if (uid == null) return 0;

      var total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final unreadMap = Map<String, dynamic>.from(data['unreadCount'] ?? {});
        total += (unreadMap[uid] as int?) ?? 0;
      }
      return total;
    });
  }
}
