import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../services/chat_service.dart';
import '../widgets/message_bubble.dart';
import 'leave_review_screen.dart';

class ChatScreen extends StatefulWidget {
  final ChatThread thread;
  final String authToken;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.thread,
    required this.authToken,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatRoomService _service;
  final _messages = <ChatMessage>[];
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  final _uuid = const Uuid();

  bool _isConnected = false;
  bool _plugIsTyping = false;
  StreamSubscription? _msgSub, _typingSub, _connSub;
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    _service = ChatRoomService(
      threadId: widget.thread.id,
      authToken: widget.authToken,
      currentUserId: widget.currentUserId,
    );
    _loadHistory();
    _service.connect();

    _msgSub = _service.messages.listen((msg) {
      setState(() => _messages.add(msg));
      _scrollToBottom();
      if (!msg.isMine(widget.currentUserId)) {
        _service.markRead(msg.id);
      }
    });
    _typingSub = _service.typingStatus.listen((typing) {
      setState(() => _plugIsTyping = typing);
    });
    _connSub = _service.connectionStatus.listen((connected) {
      setState(() => _isConnected = connected);
    });
  }

  Future<void> _loadHistory() async {
    final history = await _service.fetchHistory();
    setState(() {
      _messages.insertAll(0, history.reversed);
    });
    _scrollToBottom(jump: true);
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(pos);
      } else {
        _scrollController.animateTo(
          pos,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final message = ChatMessage(
      id: _uuid.v4(),
      threadId: widget.thread.id,
      senderId: widget.currentUserId,
      senderName: 'You',
      content: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    setState(() => _messages.add(message));
    _service.sendMessage(message);
    _textController.clear();
    _scrollToBottom();
  }

  void _openReviewScreen() {
    final jobId = widget.thread.jobId;
    if (jobId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LeaveReviewScreen(
          jobId: jobId,
          plugName: widget.thread.plugName,
          authToken: widget.authToken,
        ),
      ),
    );
  }

  void _handleTypingChange(String _) {
    _service.sendTyping(true);
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      _service.sendTyping(false);
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _typingSub?.cancel();
    _connSub?.cancel();
    _typingDebounce?.cancel();
    _service.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: widget.thread.plugAvatarUrl != null
                  ? NetworkImage(widget.thread.plugAvatarUrl!)
                  : null,
              child: widget.thread.plugAvatarUrl == null
                  ? Text(widget.thread.plugName.isNotEmpty
                      ? widget.thread.plugName[0].toUpperCase()
                      : '?')
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.thread.plugName,
                      style: const TextStyle(fontSize: 16)),
                  Text(
                    _plugIsTyping
                        ? 'typing…'
                        : (_isConnected ? 'online' : 'connecting…'),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.thread.isConfirmedJob && widget.thread.jobId != null)
            IconButton(
              icon: const Icon(Icons.star_rate_rounded),
              tooltip: 'Leave a review',
              onPressed: _openReviewScreen,
            ),
        ],
      ),
      body: Column(
        children: [
          if (!widget.thread.isConfirmedJob)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: const Text(
                'Reviews unlock once this job is marked confirmed.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return MessageBubble(
                  message: msg,
                  isMine: msg.isMine(widget.currentUserId),
                );
              },
            ),
          ),
          _ChatInputBar(
            controller: _textController,
            onChanged: _handleTypingChange,
            onSend: _handleSend,
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.onChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  minLines: 1,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.green,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
