class ChatMessage {
  ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.receiverId,
    required this.body,
    required this.isMine,
    required this.readAt,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int?,
      senderId: json['sender_id'] as int,
      receiverId: json['receiver_id'] as int,
      body: json['body'] as String,
      isMine: json['is_mine'] as bool? ?? false,
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final int? bookingId;
  final int senderId;
  final int receiverId;
  final String body;
  final bool isMine;
  final DateTime? readAt;
  final DateTime createdAt;
}
