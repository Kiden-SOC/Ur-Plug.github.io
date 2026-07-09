// lib/models/conversation.dart

import 'message.dart';

class OtherUser {
  final int id;
  final String name;
  final String? avatarUrl;

  OtherUser({required this.id, required this.name, this.avatarUrl});

  factory OtherUser.fromJson(Map<String, dynamic> json) {
    return OtherUser(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      avatarUrl: json['avatar_url'],
    );
  }
}

class Conversation {
  final int id;
  final int jobId;
  final DateTime createdAt;
  final Message? lastMessage;
  final int unreadCount;
  final OtherUser otherUser;

  Conversation({
    required this.id,
    required this.jobId,
    required this.createdAt,
    this.lastMessage,
    required this.unreadCount,
    required this.otherUser,
  });


  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      jobId: json['job'],
      createdAt: DateTime.parse(json['created_at']),
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      otherUser: OtherUser.fromJson(json['other_user']),
    );
  }
}
