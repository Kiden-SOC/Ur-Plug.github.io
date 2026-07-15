import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/provider_profile.dart';

/// One chat bubble. Renders plain text messages.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isMe = message.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.brandPrimary : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 14.5,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

/// Bottom composer: simple text field + send button. Reusable by both the
/// provider-side and customer-side chat screens so behaviour stays in sync.
class ChatComposerBar extends StatefulWidget {
  final String hintText;
  final void Function(String text) onSendText;

  const ChatComposerBar({
    super.key,
    required this.hintText,
    required this.onSendText,
  });

  @override
  State<ChatComposerBar> createState() => _ChatComposerBarState();
}

class _ChatComposerBarState extends State<ChatComposerBar> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _messageController.clear();
    setState(() {}); // Updates the send button icon state after clearing
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                      color: AppColors.brandPrimary.withValues(alpha: 0.4)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: AppColors.screenBackground.withValues(alpha: 0.4),
                  filled: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onSubmitted: (_) => _sendText(),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 22,
              backgroundColor: _messageController.text.trim().isEmpty
                  ? AppColors.brandSecondary.withValues(alpha: 0.4)
                  : AppColors.brandSecondary,
              child: IconButton(
                icon: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: _messageController.text.trim().isEmpty 
                    ? null 
                    : _sendText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

