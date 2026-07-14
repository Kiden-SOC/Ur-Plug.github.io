import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/chat_message.dart';
import '../models/chat_thread.dart';


class ChatConfig {
  static const String httpBase = 'https://api.urplug.app';
  static const String wsBase = 'wss://api.urplug.app';
}



class ChatRoomService {
  final String threadId;
  final String authToken;
  final String currentUserId;

  WebSocketChannel? _channel;
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _typingController = StreamController<bool>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Timer? _reconnectTimer;
  bool _manuallyClosed = false;
  int _retryAttempt = 0;

  ChatRoomService({
    required this.threadId,
    required this.authToken,
    required this.currentUserId,
  });

  Stream<ChatMessage> get messages => _messageController.stream;
  Stream<bool> get typingStatus => _typingController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;

  void connect() {
    _manuallyClosed = false;
    final uri = Uri.parse(
      '${ChatConfig.wsBase}/ws/chat/$threadId/?token=$authToken',
    );
    try {
      _channel = WebSocketChannel.connect(uri);
      _connectionController.add(true);
      _retryAttempt = 0;
      _channel!.stream.listen(
        _handleRawEvent,
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
      );
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleRawEvent(dynamic raw) {
    final data = jsonDecode(raw as String) as Map<String, dynamic>;
    switch (data['type']) {
      case 'chat_message':
        _messageController.add(ChatMessage.fromJson(data['message']));
        break;
      case 'typing':
        _typingController.add(data['is_typing'] == true);
        break;
      case 'read_receipt':
        
        
        break;
    }
  }

  void _handleDisconnect() {
    _connectionController.add(false);
    if (_manuallyClosed) return;
    _retryAttempt++;
    final delay = Duration(seconds: _retryAttempt.clamp(1, 10));
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, connect);
  }

  
  
  void sendMessage(ChatMessage message) {
    _channel?.sink.add(jsonEncode({
      'type': 'chat_message',
      'message': message.toJson(),
    }));
  }

  void sendTyping(bool isTyping) {
    _channel?.sink.add(jsonEncode({
      'type': 'typing',
      'is_typing': isTyping,
    }));
  }

  void markRead(String messageId) {
    _channel?.sink.add(jsonEncode({
      'type': 'read_receipt',
      'message_id': messageId,
    }));
  }

  Future<List<ChatMessage>> fetchHistory({int page = 1}) async {
    final res = await http.get(
      Uri.parse(
          '${ChatConfig.httpBase}/api/chats/threads/$threadId/messages/?page=$page'),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    if (res.statusCode != 200) return [];
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>? ?? [];
    return results
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  void dispose() {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
    _typingController.close();
    _connectionController.close();
  }
}



class InboxService {
  final String authToken;
  WebSocketChannel? _channel;
  final _threadsController = StreamController<List<ChatThread>>.broadcast();
  final Map<String, ChatThread> _threadsById = {};
  Timer? _reconnectTimer;
  bool _manuallyClosed = false;
  int _retryAttempt = 0;

  InboxService({required this.authToken});

  Stream<List<ChatThread>> get threads => _threadsController.stream;

  Future<void> start() async {
    await _loadInitial();
    _connectLive();
  }

  Future<void> _loadInitial() async {
    final res = await http.get(
      Uri.parse('${ChatConfig.httpBase}/api/chats/threads/'),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as List<dynamic>;
      _threadsById.clear();
      for (final t in body) {
        final thread = ChatThread.fromJson(t as Map<String, dynamic>);
        _threadsById[thread.id] = thread;
      }
      _emitSorted();
    }
  }

  void _connectLive() {
    _manuallyClosed = false;
    final uri =
        Uri.parse('${ChatConfig.wsBase}/ws/inbox/?token=$authToken');
    try {
      _channel = WebSocketChannel.connect(uri);
      _retryAttempt = 0;
      _channel!.stream.listen(
        _handleEvent,
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
      );
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleEvent(dynamic raw) {
    final data = jsonDecode(raw as String) as Map<String, dynamic>;
    switch (data['type']) {
      case 'thread_update':
        final thread = ChatThread.fromJson(data['thread']);
        _threadsById[thread.id] = thread;
        _emitSorted();
        break;
      case 'thread_removed':
        _threadsById.remove(data['thread_id'].toString());
        _emitSorted();
        break;
    }
  }

  void _handleDisconnect() {
    if (_manuallyClosed) return;
    _retryAttempt++;
    final delay = Duration(seconds: _retryAttempt.clamp(1, 10));
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _connectLive);
  }

  void _emitSorted() {
    final list = _threadsById.values.toList()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    _threadsController.add(list);
  }

  void dispose() {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _threadsController.close();
  }
}
