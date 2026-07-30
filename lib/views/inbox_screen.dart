import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'customer_dashboard/customer_chat_screen.dart'; // customer_chat_screen.dart — adjust path if it lives elsewhere

class CustomerInboxScreen extends StatelessWidget {
  const CustomerInboxScreen({super.key});

  static const Color brandPrimary = Color(0xFF005F73);
  static const Color brandSecondary = Color(0xFF0A9396);
  static const Color screenBackground = Color(0xFFE0F2F1);

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: myUid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 12)),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: brandPrimary));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('No conversations yet', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final providerUid = data['providerUid'] as String? ?? '';
              final providerName = data['providerName'] as String? ?? 'Provider';
              final lastMessage = data['lastMessage'] as String? ?? '';

              final unreadMap = Map<String, dynamic>.from(data['unreadCount'] ?? {});
              final unread = (unreadMap[myUid] as int?) ?? 0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE0F2F1),
                  child: Text(
                    providerName.isNotEmpty ? providerName[0].toUpperCase() : '?',
                    style: const TextStyle(color: brandPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  providerName,
                  style: TextStyle(
                    fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                    color: unread > 0 ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                trailing: unread > 0
                    ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: brandSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unread',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(providerUid: providerUid, providerName: providerName),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}