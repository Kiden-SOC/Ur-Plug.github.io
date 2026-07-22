import 'dart:async';
import 'package:flutter/material.dart';

import '../models/notification_item.dart';
import '../services/notification_service.dart';
import '../widgets/notification_tile.dart';
import 'customer_dashboard/customer_chat_screen.dart';
import 'reviews_list_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final NotificationService service;
  final String authToken;

  const NotificationsScreen({
    super.key,
    required this.service,
    required this.authToken,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notifications = <AppNotification>[];
  StreamSubscription? _liveSub;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _liveSub = widget.service.onNotification.listen((n) {
      setState(() => _notifications.insert(0, n));
    });
  }

  Future<void> _load() async {
    final list = await widget.service.fetchAll();
    setState(() {
      _notifications
        ..clear()
        ..addAll(list);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    super.dispose();
  }

  void _handleTap(AppNotification notification) async {
    if (!notification.isRead) {
      await widget.service.markRead(notification.id);
      setState(() => notification.isRead = true);
    }
    if (!mounted) return;

    switch (notification.type) {
      case NotificationType.newMessage:
        final data = notification.data;
        if (data['plug_id'] == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              providerUid: data['plug_id'].toString(),
              providerName: data['plug_name'] ?? '',
            ),
          ),
        );
        break;
      case NotificationType.newReview:
        final data = notification.data;
        if (data['plug_id'] == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReviewsListScreen(
              plugId: data['plug_id'].toString(),
              plugName: data['plug_name'] ?? '',
              authToken: widget.authToken,
            ),
          ),
        );
        break;
      case NotificationType.jobStatus:
      case NotificationType.unknown:
      // No dedicated job-detail screen yet — surface it inline for now.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(notification.body.isNotEmpty
              ? notification.body
              : notification.title)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await widget.service.markAllRead();
              setState(() {
                for (final n in _notifications) {
                  n.isRead = true;
                }
              });
            },
            child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(
        child: Text('No notifications yet.', style: TextStyle(color: Colors.black54)),
      )
          : ListView.separated(
        itemCount: _notifications.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) => NotificationTile(
          notification: _notifications[i],
          onTap: () => _handleTap(_notifications[i]),
        ),
      ),
    );
  }
}