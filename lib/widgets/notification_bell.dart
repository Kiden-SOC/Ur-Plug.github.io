import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import 'notifications_screen.dart';

class NotificationBell extends StatelessWidget {
  final NotificationService service;
  final String authToken;

  const NotificationBell({
    super.key,
    required this.service,
    required this.authToken,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: service.unreadCount,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(
                    service: service,
                    authToken: authToken,
                  ),
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
