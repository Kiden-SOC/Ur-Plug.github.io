import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/provider_profile.dart';
import '../../widgets/chat_widgets.dart';

/// Provider-side chat UI: same bubble language as the customer chat
/// screen, but from the provider's perspective (customer on the left,
/// provider replies on the right). Supports both text messages and
/// recorded voice notes.
class ProviderChatScreen extends StatefulWidget {
  final String customerName;
  const ProviderChatScreen({super.key, required this.customerName});

  @override
  State<ProviderChatScreen> createState() => _ProviderChatScreenState();
}

class _ProviderChatScreenState extends State<ProviderChatScreen> {
  final _scrollController = ScrollController();

  // No backend endpoint connected yet — the conversation starts empty.
  // Once messaging is live, load the real message history for this
  // thread here (e.g. via an ApiService.fetchMessages(threadId) call)
  // instead of leaving this list empty.
  final List<ChatMessage> _messages = [];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendText(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isMe: true));
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha:0.2),
              child: const Icon(Icons.person_outline,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.customerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text('Customer',
                      style:
                          TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 44,
                              color: AppColors.brandPrimary.withValues(alpha:0.25)),
                          const SizedBox(height: 12),
                          const Text(
                            'No messages yet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Start the conversation below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        ChatBubble(message: _messages[index]),
                  ),
          ),
          ChatComposerBar(
            hintText: 'Reply to ${widget.customerName}...',
            onSendText: _sendText,
          ),
        ],
      ),
    );
  }
}