import '../models/booking.dart';
import 'api_client.dart';

class BookingRepository {
  BookingRepository(this._client);

  final ApiClient _client;

  Future<List<Booking>> fetchMine() async {
    final items = await _client.getAllPages('/bookings?per_page=50');
    return items
        .map((item) => Booking.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Booking> fetchOne(int id) async {
    final response = await _client.get('/bookings/$id');
    return Booking.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Booking> create({
    required int tripId,
    required int goodId,
    Payer payer = Payer.sender,
  }) async {
    final response = await _client.post('/bookings', {
      'trip_id': tripId,
      'good_id': goodId,
      'payer': payer.name,
    });
    return Booking.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Booking> accept(int id) async {
    final response = await _client.post('/bookings/$id/accept', {});
    return Booking.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Booking> reject(int id) async {
    final response = await _client.post('/bookings/$id/reject', {});
    return Booking.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Booking> markInTransit(int id) async {
    final response = await _client.post('/bookings/$id/mark-in-transit', {});
    return Booking.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Booking> markArrived(int id) async {
    final response = await _client.post('/bookings/$id/mark-arrived', {});
    return Booking.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Booking> complete(int id, {required String proofPhotoPath}) async {
    final response = await _client.postMultipart('/bookings/$id/complete', {
      'inspection_confirmed': 'true',
    }, filePath: proofPhotoPath);
    return Booking.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Booking> cancel(int id) async {
    final response = await _client.post('/bookings/$id/cancel', {});
    return Booking.fromJson(response['data'] as Map<String, dynamic>);
  }
}
