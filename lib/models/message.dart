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
