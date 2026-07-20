import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/notification_item.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isRead ? Colors.transparent : Colors.green.withOpacity(0.05),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _iconColor().withOpacity(0.15),
          child: Icon(_icon(), color: _iconColor(), size: 20),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: notification.body.isNotEmpty
            ? Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        trailing: Text(
          DateFormat('HH:mm').format(notification.createdAt),
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ),
    );
  }

  IconData _icon() {
    switch (notification.type) {
      case NotificationType.newMessage:
        return Icons.chat_bubble_outline;
      case NotificationType.newReview:
        return Icons.star_outline;
      case NotificationType.jobStatus:
        return Icons.work_outline;
      case NotificationType.unknown:
        return Icons.notifications_outlined;
    }
  }

  Color _iconColor() {
    switch (notification.type) {
      case NotificationType.newMessage:
        return Colors.green;
      case NotificationType.newReview:
        return Colors.amber.shade800;
      case NotificationType.jobStatus:
        return Colors.blueGrey;
      case NotificationType.unknown:
        return Colors.grey;
    }
  }
}
