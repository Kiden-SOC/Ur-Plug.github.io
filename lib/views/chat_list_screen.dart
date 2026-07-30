// lib/screens/chat_list_screen.dart
//
// Displays the current user's conversations with a live WhatsApp-style
// unread badge on each row. Tapping a chat opens it and clears the badge.
//
// Wire this up by importing ChatService from lib/services/chat_service.dart
// and ChatScreen from wherever your existing conversation screen lives.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
// import 'chat_screen.dart'; // <- your existing conversation screen

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final currentUid = _chatService.currentUid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          // Optional single badge showing total unread across all chats.
          StreamBuilder<int>(
            stream: _chatService.totalUnreadStream(),
            builder: (context, snapshot) {
              final total = snapshot.data ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Badge(
                    isLabelVisible: total > 0,
                    label: Text('$total'),
                    child: const Icon(Icons.notifications),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _chatService.chatListStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final chats = snapshot.data?.docs ?? [];
          if (chats.isEmpty) {
            return const Center(child: Text('No conversations yet'));
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = chats[index];
              final data = doc.data();
              final chatId = doc.id;

              final participants =
                  List<String>.from(data['participants'] ?? []);
              final otherUserId = participants.firstWhere(
                (id) => id != currentUid,
                orElse: () => '',
              );

              final unreadMap =
                  Map<String, dynamic>.from(data['unreadCount'] ?? {});
              final unread = (unreadMap[currentUid] as int?) ?? 0;

              final lastMessage = data['lastMessage'] as String? ?? '';
              // Replace with a real display name lookup (from a users
              // collection or a participantNames map) once you have one.
              final displayName = data['otherUserName'] as String? ??
                  (otherUserId.isNotEmpty ? otherUserId : 'Unknown');

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                  displayName,
                  style: TextStyle(
                    fontWeight:
                        unread > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight:
                        unread > 0 ? FontWeight.bold : FontWeight.normal,
                    color: unread > 0 ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                trailing: unread > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : null,
                onTap: () async {
                  await _chatService.markChatAsRead(chatId);
                  if (!context.mounted) return;
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (_) => ChatScreen(
                  //       chatId: chatId,
                  //       otherUserId: otherUserId,
                  //       otherUserName: displayName,
                  //     ),
                  //   ),
                  // );
                },
              );
            },
          );
        },
      ),
    );
  }
}
