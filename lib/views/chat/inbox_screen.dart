// lib/screens/inbox_screen.dart

import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  final ChatService chatService;

  const InboxScreen({super.key, required this.chatService});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late Future<List<Conversation>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _conversationsFuture = widget.chatService.fetchConversations();
  }

  Future<void> _refresh() async {
    setState(() {
      _conversationsFuture = widget.chatService.fetchConversations();
    });
    await _conversationsFuture;
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0 && now.day == dt.day) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return "$h:$m";
    } else if (diff.inDays < 7) {
      const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      return days[dt.weekday - 1];
    }
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Conversation>>(
          future: _conversationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      "Couldn't load your chats. Pull down to retry.\n${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              );
            }
            final conversations = snapshot.data ?? [];
            if (conversations.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text("No conversations yet.")),
                  ),
                ],
              );
            }
            return ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
              itemBuilder: (context, index) {
                final convo = conversations[index];
                final hasUnread = convo.unreadCount > 0;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundImage: convo.otherUser.avatarUrl != null
                        ? NetworkImage(convo.otherUser.avatarUrl!)
                        : null,
                    child: convo.otherUser.avatarUrl == null
                        ? Text(convo.otherUser.name.isNotEmpty
                            ? convo.otherUser.name[0].toUpperCase()
                            : "?")
                        : null,
                  ),
                  title: Text(
                    convo.otherUser.name,
                    style: TextStyle(
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    convo.lastMessage?.content ?? "Say hello 👋",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasUnread ? Colors.black87 : Colors.grey[600],
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (convo.lastMessage != null)
                        Text(
                          _timeLabel(convo.lastMessage!.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      const SizedBox(height: 6),
                      if (hasUnread)
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            "${convo.unreadCount}",
                            style: const TextStyle(fontSize: 11, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatService: widget.chatService,
                          conversationId: convo.id,
                          otherUserName: convo.otherUser.name,
                          otherUserAvatarUrl: convo.otherUser.avatarUrl,
                        ),
                      ),
                    ).then((_) => _refresh());
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
