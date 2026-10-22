import 'api_client.dart';

class RatingRepository {
  RatingRepository(this._client);

  final ApiClient _client;

  Future<void> rate({
    required int bookingId,
    required int stars,
    String? comment,
  }) {
    return _client.post('/bookings/$bookingId/ratings', {
      'stars': stars,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    });
  }
}
