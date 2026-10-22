import 'user.dart';

class Rating {
  Rating({
    required this.id,
    required this.bookingId,
    required this.stars,
    required this.comment,
    required this.rater,
    required this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int,
      stars: json['stars'] as int,
      comment: json['comment'] as String?,
      rater: User.fromJson(json['rater'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final int bookingId;
  final int stars;
  final String? comment;
  final User rater;
  final DateTime createdAt;
}
