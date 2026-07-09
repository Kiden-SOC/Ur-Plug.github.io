// lib/models/message.dart

class Message {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  // Parses a message from a REST API response, e.g.
  // GET /api/messaging/conversations/{id}/messages/
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversation'],
      senderId: json['sender'],
      senderName: json['sender_name'] ?? '',
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
    );
  }

  // Parses a message pushed over the WebSocket, e.g.
  // { "type": "chat_message", "message_id": 13, "sender_id": 7, ... }
  factory Message.fromSocketJson(Map<String, dynamic> json, int conversationId) {
    return Message(
      id: json['message_id'],
      conversationId: conversationId,
      senderId: json['sender_id'],
      senderName: json['sender_name'] ?? '',
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }
}
