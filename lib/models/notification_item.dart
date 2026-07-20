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

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      type: _typeFromString(json['event_type']),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      isRead: json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static NotificationType _typeFromString(String? s) {
    switch (s) {
      case 'new_message':
        return NotificationType.newMessage;
      case 'new_review':
        return NotificationType.newReview;
      case 'job_status':
        return NotificationType.jobStatus;
      default:
        return NotificationType.unknown;
    }
  }
}
