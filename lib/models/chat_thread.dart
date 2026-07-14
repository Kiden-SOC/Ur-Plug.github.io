class ChatThread {
  final String id;
  final String plugId;
  final String plugName;
  final String? plugAvatarUrl;
  String lastMessage;
  DateTime lastMessageTime;
  int unreadCount;
  bool isOnline;
  final String? jobId;
  // Gates the review system: a review can only be posted once this is true.
  bool isConfirmedJob;

  ChatThread({
    required this.id,
    required this.plugId,
    required this.plugName,
    this.plugAvatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.jobId,
    this.isConfirmedJob = false,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'].toString(),
      plugId: json['plug_id'].toString(),
      plugName: json['plug_name'] ?? '',
      plugAvatarUrl: json['plug_avatar_url'],
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: DateTime.parse(json['last_message_time']),
      unreadCount: json['unread_count'] ?? 0,
      isOnline: json['is_online'] ?? false,
      jobId: json['job_id']?.toString(),
      isConfirmedJob: json['is_confirmed_job'] ?? false,
    );
  }

  ChatThread copyWithLatest({
    required String lastMessage,
    required DateTime lastMessageTime,
    int? unreadCount,
  }) {
    return ChatThread(
      id: id,
      plugId: plugId,
      plugName: plugName,
      plugAvatarUrl: plugAvatarUrl,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline,
      jobId: jobId,
      isConfirmedJob: isConfirmedJob,
    );
  }
}
