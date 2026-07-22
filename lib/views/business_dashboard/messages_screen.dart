import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../state/provider_profile_controller.dart';
import '../../widgets/shared_widgets.dart';
import 'provider_chat_screen.dart';

/// Provider inbox — every conversation a customer has started with them.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderProfileController>();

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Messages',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: controller.threads.isEmpty
          ? const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'No conversations yet',
              subtitle:
                  'When customers message you about a job, the conversation will appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.threads.length,
              separatorBuilder: (context, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final thread = controller.threads[index];
                return UrPlugCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.brandPrimary.withValues(alpha:0.1),
                      child: const Icon(Icons.person_outline,
                          color: AppColors.brandPrimary),
                    ),
                    title: Text(thread.customerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.brandPrimary)),
                    subtitle: Text(
                      thread.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: thread.unreadCount > 0
                            ? AppColors.textDark
                            : AppColors.textMuted,
                        fontWeight: thread.unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(thread.time,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        if (thread.unreadCount > 0)
                          CircleAvatar(
                            radius: 9,
                            backgroundColor: AppColors.brandSecondary,
                            child: Text('${thread.unreadCount}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    onTap: () {
                      context
                          .read<ProviderProfileController>()
                          .markThreadRead(thread.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProviderChatScreen(
                            customerUid: thread.id,
                            customerName: thread.customerName,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
