import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../state/customer_profile_controller.dart';

class ChatScreen extends StatefulWidget {
  final String providerUid;
  final String providerName;
  const ChatScreen({super.key, required this.providerUid, required this.providerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color brandPrimary = Color(0xFF005F73);
  static const Color brandSecondary = Color(0xFF0A9396);
  static const Color screenBackground = Color(0xFFE0F2F1);

  final _messageController = TextEditingController();
  late final String _chatId;
  late final String _myUid;

  // The name shown in the AppBar and written to the chat doc. Starts as
  // whatever the caller passed in, then gets overwritten with the real
  // businessName from Firestore once it loads — this way a stale/fallback
  // name passed in from a list item can never get "burned in" permanently.
  late String _providerDisplayName;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _chatId = _myUid.compareTo(widget.providerUid) < 0
        ? '${_myUid}_${widget.providerUid}'
        : '${widget.providerUid}_$_myUid';
    _providerDisplayName = widget.providerName;
    _loadProviderName();
    _markAsRead();
  }

  Future<void> _loadProviderName() async {
    if (widget.providerUid.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(widget.providerUid)
          .get();
      final businessName = (doc.data()?['businessName'] ?? '').toString();
      if (mounted && businessName.isNotEmpty) {
        setState(() => _providerDisplayName = businessName);
      }
    } catch (_) {
      // Keep whatever name we were passed in if the lookup fails.
    }
  }

  // Clears this customer's unread badge for this chat. Only touches the
  // doc if it already exists — writing a bare 'unreadCount.$_myUid' field
  // via set-merge on a chat that doesn't exist yet would create a doc
  // missing the 'participants' array, which then fails every rule check
  // that reads resource.data.participants.
  Future<void> _markAsRead() async {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);
    try {
      final snapshot = await chatRef.get();
      if (snapshot.exists) {
        await chatRef.update({'unreadCount.$_myUid': 0});
      }
    } catch (_) {
      // Non-fatal — worst case the badge doesn't clear until next update.
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    // Grab the logged-in customer's display name so the provider-side
    // chat list (and this screen's own chat list) can show a real name
    // instead of a raw UID.
    final customerName = context.read<CustomerProfileController>().profile.name;

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);

    // Dotted keys like 'unreadCount.<uid>' only expand into a nested map
    // path inside update() — inside set(merge:true) they're taken as one
    // literal field name (dots included), which silently creates junk
    // top-level fields instead of updating the unreadCount map. So the
    // base fields go through set/merge, and unreadCount gets its own
    // update() call right after.
    await chatRef.set({
      'participants': [_myUid, widget.providerUid],
      'providerUid': widget.providerUid,
      'providerName': _providerDisplayName,
      'customerUid': _myUid,
      'customerName': customerName.isNotEmpty ? customerName : 'Customer',
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatRef.update({
      'unreadCount.${widget.providerUid}': FieldValue.increment(1),
      'unreadCount.$_myUid': 0,
    });

    await chatRef.collection('messages').add({
      'senderUid': _myUid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: Text(_providerDisplayName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: brandPrimary));
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('Say hello 👋', style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isMe = data['senderUid'] == _myUid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? brandPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14.5),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        fillColor: screenBackground.withValues(alpha: 0.4),
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: brandSecondary,
                    child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: _sendMessage),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}