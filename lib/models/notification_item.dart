import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { newMessage, newReview, jobStatus, unknown }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> doc) {
    return AppNotification(
      id: id,
      type: _typeFromString(doc['type']),
      title: doc['title'] ?? '',
      body: doc['body'] ?? '',
      data: Map<String, dynamic>.from(doc['data'] ?? {}),
      isRead: doc['isRead'] == true,
      createdAt: (doc['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static NotificationType _typeFromString(String? s) {
    switch (s) {
      case 'newMessage':
        return NotificationType.newMessage;
      case 'newReview':
        return NotificationType.newReview;
      case 'jobStatus':
        return NotificationType.jobStatus;
      default:
        return NotificationType.unknown;
    }
  }
}