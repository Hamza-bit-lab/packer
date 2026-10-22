import 'api_client.dart';

class ReportRepository {
  ReportRepository(this._client);

  final ApiClient _client;

  Future<void> reportUser(
    int userId, {
    required String reason,
    String? details,
    int? bookingId,
  }) {
    return _client.post('/users/$userId/reports', {
      'reason': reason,
      if (details != null && details.trim().isNotEmpty)
        'details': details.trim(),
      if (bookingId != null) 'booking_id': bookingId,
    });
  }
}
