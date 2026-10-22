import '../models/trip.dart';
import 'api_client.dart';

class TripRepository {
  TripRepository(this._client);

  final ApiClient _client;

  Future<List<Trip>> fetchMine(int userId) async {
    final items = await _client.getAllPages(
      '/trips?user_id=$userId&per_page=50',
    );
    return items
        .map((item) => Trip.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Trip> fetchOne(int id) async {
    final response = await _client.get('/trips/$id');
    return Trip.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Other trips on the same route, for the compare-prices prompt.
  Future<List<Trip>> fetchByRoute({
    required String fromCity,
    required String toCity,
  }) async {
    final query =
        'from_city=${Uri.encodeQueryComponent(fromCity)}&to_city=${Uri.encodeQueryComponent(toCity)}';
    final response = await _client.get('/trips?$query&per_page=20&sort=rating');
    return (response['data'] as List)
        .map((item) => Trip.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Trip> create({
    required String fromCity,
    required String toCity,
    required DateTime departureDateTime,
    required String airlineName,
    required double maxWeightKg,
    required double ratePerKg,
    required String currencyType,
    required DeliveryMethod deliveryMethod,
    required PickupMethod pickupMethod,
    required bool termsAccepted,
    String? photoPath,
  }) async {
    final response = await _client.postMultipart('/trips', {
      'from_city': fromCity,
      'to_city': toCity,
      'departure_date_time': departureDateTime.toIso8601String(),
      'airline_name': airlineName,
      'max_weight_kg': '$maxWeightKg',
      'rate_per_kg': '$ratePerKg',
      'currency_type': currencyType,
      'delivery_method': deliveryMethod.apiValue,
      'pickup_method': pickupMethod.apiValue,
      'terms_accepted': '$termsAccepted',
    }, filePath: photoPath);
    return Trip.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Trip> update(
    int id, {
    String? fromCity,
    String? toCity,
    DateTime? departureDateTime,
    String? airlineName,
    double? maxWeightKg,
    double? ratePerKg,
    String? currencyType,
    DeliveryMethod? deliveryMethod,
    PickupMethod? pickupMethod,
    String? photoPath,
  }) async {
    final response = await _client.patchMultipart(
      '/trips/$id',
      {
        if (fromCity != null) 'from_city': fromCity,
        if (toCity != null) 'to_city': toCity,
        if (departureDateTime != null)
          'departure_date_time': departureDateTime.toIso8601String(),
        if (airlineName != null) 'airline_name': airlineName,
        if (maxWeightKg != null) 'max_weight_kg': '$maxWeightKg',
        if (ratePerKg != null) 'rate_per_kg': '$ratePerKg',
        if (currencyType != null) 'currency_type': currencyType,
        if (deliveryMethod != null) 'delivery_method': deliveryMethod.apiValue,
        if (pickupMethod != null) 'pickup_method': pickupMethod.apiValue,
      },
      filePath: photoPath,
      fileField: 'photo',
    );
    return Trip.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete('/trips/$id');
}
