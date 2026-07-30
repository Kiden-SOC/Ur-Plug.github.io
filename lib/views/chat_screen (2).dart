// lib/services/chat_service.dart
//
// Firestore-backed implementation of ChatRoomService. Adapts your
// ChatMessage / ChatThread models to Firestore's document shape so
// ChatScreen doesn't need to change.
//
// Firestore structure used:
//
// chats/{chatId}
//   participants: [uid1, uid2]
//   lastMessage: string
//   lastMessageTime: Timestamp
//   unreadCount: { uid1: 0, uid2: 0 }
//   typing: { uid1: false, uid2: false }
//
// chats/{chatId}/messages/{messageId}
//   senderUid: string
//   senderName: string
//   content: string
//   messageType: string   (matches MessageType enum names)
//   mediaUrl: string?
//   createdAt: Timestamp

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import '../models/chat_thread.dart';

class ChatRoomService {
  ChatRoomService({
    required this.threadId,
    required this.authToken, // unused with Firestore — kept so ChatScreen's constructor call doesn't need to change
    required this.currentUserId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String threadId;
  final String authToken;
  final String currentUserId;
  final FirebaseFirestore _firestore;

  final _messagesController = StreamController<ChatMessage>.broadcast();
  final _typingController = StreamController<bool>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<ChatMessage> get messages => _messagesController.stream;
  Stream<bool> get typingStatus => _typingController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;

  // Tracks message ids already known to the UI (via history load or this
  // user's own optimistic send) so the live listener never re-emits or
  // duplicates them.
  final Set<String> _deliveredIds = {};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _threadSub;

  DocumentReference<Map<String, dynamic>> get _chatRef =>
      _firestore.collection('chats').doc(threadId);

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      _chatRef.collection('messages');

  /// Fetches existing message history once, newest-first (ChatScreen
  /// reverses it before inserting). Call this before [connect].
  Future<List<ChatMessage>> fetchHistory() async {
    final snapshot =
    await _messagesRef.orderBy('createdAt', descending: true).get();

    final result = <ChatMessage>[];
    for (final doc in snapshot.docs) {
      _deliveredIds.add(doc.id);
      result.add(_messageFromDoc(doc));
    }
    return result;
  }

  /// Starts listening for new messages, the other participant's typing
  /// flag, and reports a connected state (Firestore doesn't have an
  /// explicit handshake the way a socket does, so this fires true
  /// immediately and false only if a listener errors out).
  void connect() {
    _connectionController.add(true);

    _messagesSub = _messagesRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final doc = change.doc;
        if (_deliveredIds.contains(doc.id)) continue;
        _deliveredIds.add(doc.id);
        _messagesController.add(_messageFromDoc(doc));
      }
    }, onError: (_) {
      _connectionController.add(false);
    });

    _threadSub = _chatRef.snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data == null) return;

      final participants = List<String>.from(data['participants'] ?? []);
      final otherUid = participants.firstWhere(
            (id) => id != currentUserId,
        orElse: () => '',
      );

      final typingMap = Map<String, dynamic>.from(data['typing'] ?? {});
      _typingController.add(otherUid.isNotEmpty && typingMap[otherUid] == true);
    }, onError: (_) {
      _connectionController.add(false);
    });
  }

  /// Sends a message. Uses [message.id] as the Firestore doc id itself,
  /// so when this same write is echoed back through the live listener,
  /// it's recognized as already-delivered and never shown twice.
  Future<void> sendMessage(ChatMessage message) async {
    _deliveredIds.add(message.id);

    final chatSnapshot = await _chatRef.get();
    final participants =
    List<String>.from(chatSnapshot.data()?['participants'] ?? []);

    final batch = _firestore.batch();

    batch.set(_messagesRef.doc(message.id), {
      'senderUid': message.senderId,
      'senderName': message.senderName,
      'content': message.content,
      'messageType': message.type.name,
      'mediaUrl': message.mediaUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final chatUpdate = <String, dynamic>{
      'lastMessage': message.content,
      'lastMessageTime': FieldValue.serverTimestamp(),
    };
    for (final uid in participants) {
      if (uid == currentUserId) continue;
      chatUpdate['unreadCount.$uid'] = FieldValue.increment(1);
    }
    batch.update(_chatRef, chatUpdate);

    await batch.commit();
  }

  /// Resets this user's unread badge for the whole chat. Your Firestore
  /// rules only allow `create` on message docs (no `update`), so this
  /// can't flip an individual message's status to "read" without adding
  /// a new rule — it clears the chat-level unread count instead, which
  /// is what actually drives the badge in the chat list.
  Future<void> markRead(String messageId) async {
    await _chatRef.update({'unreadCount.$currentUserId': 0});
  }

  /// Writes this user's typing flag onto the shared chat doc; the other
  /// participant's [connect] listener picks it up via [typingStatus].
  Future<void> sendTyping(bool isTyping) async {
    await _chatRef.update({'typing.$currentUserId': isTyping});
  }

  ChatMessage _messageFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAt = data['createdAt'];

    return ChatMessage(
      id: doc.id,
      threadId: threadId,
      senderId: data['senderUid'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      type: _typeFromString(data['messageType']),
      timestamp: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      status: MessageStatus.sent,
      mediaUrl: data['mediaUrl'],
    );
  }

  static MessageType _typeFromString(String? s) {
    switch (s) {
      case 'voiceNote':
        return MessageType.voiceNote;
      case 'image':
        return MessageType.image;
      case 'workAgreement':
        return MessageType.workAgreement;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  void dispose() {
    _messagesSub?.cancel();
    _threadSub?.cancel();
    _messagesController.close();
    _typingController.close();
    _connectionController.close();
  }
}
