enum MessageStatus { sending, sent, delivered, read, failed }

enum MessageType { text, voiceNote, image, workAgreement, system }

class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  MessageStatus status;
  final String? mediaUrl;

  ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.mediaUrl,
  });

  bool isMine(String currentUserId) => senderId == currentUserId;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      threadId: json['thread_id'].toString(),
      senderId: json['sender_id'].toString(),
      senderName: json['sender_name'] ?? '',
      content: json['content'] ?? '',
      type: _typeFromString(json['message_type']),
      timestamp: DateTime.parse(json['timestamp']),
      status: _statusFromString(json['status']),
      mediaUrl: json['media_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'thread_id': threadId,
        'sender_id': senderId,
        'sender_name': senderName,
        'content': content,
        'message_type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'media_url': mediaUrl,
      };

  ChatMessage copyWith({MessageStatus? status}) {
    return ChatMessage(
      id: id,
      threadId: threadId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      type: type,
      timestamp: timestamp,
      status: status ?? this.status,
      mediaUrl: mediaUrl,
    );
  }

  static MessageType _typeFromString(String? s) {
    switch (s) {
      case 'voice_note':
        return MessageType.voiceNote;
      case 'image':
        return MessageType.image;
      case 'work_agreement':
        return MessageType.workAgreement;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  static MessageStatus _statusFromString(String? s) {
    switch (s) {
      case 'sending':
        return MessageStatus.sending;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }
}
