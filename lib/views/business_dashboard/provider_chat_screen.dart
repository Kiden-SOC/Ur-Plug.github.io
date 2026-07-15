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

  late final List<ChatMessage> _messages = [
    const ChatMessage(
        text:
            'Hello! I need help with a job at my place. Are you available this week?',
        isMe: false),
    const ChatMessage(
        text:
            'Hi there! Yes, I have openings from Wednesday afternoon. What is the issue exactly?',
        isMe: true),
    const ChatMessage(
        text:
            'The circuit breaker keeps tripping whenever we switch on the water heater.',
        isMe: false),
  ];

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
              backgroundColor: Colors.white.withValues(alpha: 0.2),
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
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  ChatBubble(message: _messages[index]),
            ),
          ),
          ChatComposerBar(
            hintText: 'Type a message...',
            onSendText: (text) => _sendText(text),
          )
        ],
      ),
    );
  }
}