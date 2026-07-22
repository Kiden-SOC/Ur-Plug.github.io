import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat_thread.dart';
import '../services/chat_service.dart';
import 'customer_dashboard/customer_chat_screen.dart';

class InboxScreen extends StatefulWidget {
  final String authToken;
  final String currentUserId;

  const InboxScreen({
    super.key,
    required this.authToken,
    required this.currentUserId,
  });

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late final InboxService _inboxService;

  @override
  void initState() {
    super.initState();
    _inboxService = InboxService(authToken: widget.authToken);
    _inboxService.start();
  }

  @override
  void dispose() {
    _inboxService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<List<ChatThread>>(
        stream: _inboxService.threads,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final threads = snapshot.data!;
          if (threads.isEmpty) {
            return const Center(
              child: Text(
                'No conversations yet.\nMatch with a plug to start chatting.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            );
          }
          return ListView.separated(
            itemCount: threads.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
            itemBuilder: (context, index) => _ThreadTile(
              thread: threads[index],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    providerUid: threads[index].plugId,
                    providerName: threads[index].plugName,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final ChatThread thread;
  final VoidCallback onTap;

  const _ThreadTile({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnread = thread.unreadCount > 0;
    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: thread.plugAvatarUrl != null
                ? NetworkImage(thread.plugAvatarUrl!)
                : null,
            child: thread.plugAvatarUrl == null
                ? Text(thread.plugName.isNotEmpty
                    ? thread.plugName[0].toUpperCase()
                    : '?')
                : null,
          ),
          if (thread.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        thread.plugName,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        thread.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasUnread ? Colors.black87 : Colors.black54,
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTime(thread.lastMessageTime),
            style: TextStyle(
              fontSize: 12,
              color: hasUnread ? Colors.green : Colors.black45,
            ),
          ),
          const SizedBox(height: 6),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${thread.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
          else if (thread.isConfirmedJob)
            const Icon(Icons.verified, size: 16, color: Colors.blueGrey),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final isToday = now.year == time.year &&
        now.month == time.month &&
        now.day == time.day;
    return isToday
        ? DateFormat('HH:mm').format(time)
        : DateFormat('d MMM').format(time);
  }
}
