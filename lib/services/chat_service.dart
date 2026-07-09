// lib/services/chat_service.dart


import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class ChatService {
  static const String baseUrl = "http://10.0.2.2:8000";
  static const String wsBaseUrl = "ws://10.0.2.2:8000";

  final String authToken;

  ChatService({required this.authToken});

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "Authorization": "Token $authToken",
      };

  Future<List<Conversation>> fetchConversations() async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/messaging/conversations/"),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to load conversations (${response.statusCode})");
    }
    final List data = jsonDecode(response.body);
    return data.map((json) => Conversation.fromJson(json)).toList();
  }

  Future<List<Message>> fetchMessages(int conversationId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/messaging/conversations/$conversationId/messages/"),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to load messages (${response.statusCode})");
    }
    final body = jsonDecode(response.body);
    final List data = body is Map ? body["results"] ?? [] : body;
    return data.map((json) => Message.fromJson(json)).toList();
  }

  
  Future<Message> sendMessageRest(int conversationId, String content) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/messaging/conversations/$conversationId/send/"),
      headers: _headers,
      body: jsonEncode({"content": content}),
    );
    if (response.statusCode != 201) {
      throw Exception("Failed to send message (${response.statusCode})");
    }
    return Message.fromJson(jsonDecode(response.body));
  }

  


  WebSocketChannel connect(int conversationId) {
    final uri = Uri.parse(
      "$wsBaseUrl/ws/chat/$conversationId/?token=$authToken",
    );
    return WebSocketChannel.connect(uri);
  }

  
  Stream<Message> messageStream(WebSocketChannel channel, int conversationId) {
    return channel.stream.map((raw) {
      final json = jsonDecode(raw);
      return Message.fromSocketJson(json, conversationId);
    });
  }

  void sendOverSocket(WebSocketChannel channel, String content) {
    channel.sink.add(jsonEncode({"content": content}));
  }
}
