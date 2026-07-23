import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/shared_widgets.dart';
import 'provider_chat_screen.dart';

/// Provider inbox — every real conversation a customer has started with them.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Messages',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.brandPrimary,
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
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.brandPrimary));
          }
          final chats = snapshot.data!.docs;
          if (chats.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'No conversations yet',
              subtitle:
              'When customers message you about a job, the conversation will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (context, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = chats[index];
              final data = doc.data() as Map<String, dynamic>;
              final List participants = data['participants'] ?? [];
              final String otherUid =
              participants.firstWhere((p) => p != myUid, orElse: () => '');

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUid).get(),
                builder: (context, userSnapshot) {
                  final customerName = userSnapshot.hasData && userSnapshot.data!.exists
                      ? (userSnapshot.data!.data() as Map<String, dynamic>)['fullName'] ?? 'Customer'
                      : 'Customer';

                  return UrPlugCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                        child: const Icon(Icons.person_outline,
                            color: AppColors.brandPrimary),
                      ),
                      title: Text(customerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.brandPrimary)),
                      subtitle: Text(
                        data['lastMessage'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProviderChatScreen(
                              customerUid: otherUid,
                              customerName: customerName,
                            ),
                          ),
                        );
                      },
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