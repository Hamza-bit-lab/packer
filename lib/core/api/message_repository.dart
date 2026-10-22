import '../models/chat_message.dart';
import '../models/conversation.dart';
import 'api_client.dart';

/// A direct conversation with another user, not tied to a booking.
class MessageRepository {
  MessageRepository(this._client);

  final ApiClient _client;

  Future<List<Conversation>> fetchConversations() async {
    final response = await _client.get('/conversations');
    return (response['data'] as List)
        .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final response = await _client.get('/messages/unread-count');
    return response['unread_count'] as int? ?? 0;
  }

  Future<List<ChatMessage>> fetchForUser(int otherUserId) async {
    final response = await _client.get('/users/$otherUserId/messages');
    return (response['data'] as List)
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> send(int otherUserId, String body) async {
    final response = await _client.post('/users/$otherUserId/messages', {
      'body': body,
    });
    return ChatMessage.fromJson(response['data'] as Map<String, dynamic>);
  }
}
