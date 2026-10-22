import 'chat_message.dart';
import 'user.dart';

/// One Inbox row: other user, last message, unread count.
class Conversation {
  Conversation({
    required this.otherUser,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      otherUser: User.fromJson(json['other_user'] as Map<String, dynamic>),
      lastMessage: ChatMessage.fromJson(
        json['last_message'] as Map<String, dynamic>,
      ),
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  final User otherUser;
  final ChatMessage lastMessage;
  final int unreadCount;
}
