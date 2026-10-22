import '../models/good.dart';
import '../models/trip.dart' show PickupMethod, PickupMethodApi;
import 'api_client.dart';

class GoodRepository {
  GoodRepository(this._client);

  final ApiClient _client;

  Future<List<Good>> fetchMine(int userId) async {
    final items = await _client.getAllPages(
      '/goods?user_id=$userId&per_page=50',
    );
    return items
        .map((item) => Good.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Good> fetchOne(int id) async {
    final response = await _client.get('/goods/$id');
    return Good.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Good> create({
    required String fromCity,
    required String toCity,
    required String itemDescription,
    required String receiverEmail,
    required double weightKg,
    required double offeredReward,
    required String currencyType,
    required PickupMethod pickupPreference,
    required bool termsAccepted,
    String? photoPath,
  }) async {
    final response = await _client.postMultipart('/goods', {
      'from_city': fromCity,
      'to_city': toCity,
      'item_description': itemDescription,
      'receiver_email': receiverEmail,
      'weight_kg': '$weightKg',
      'offered_reward': '$offeredReward',
      'currency_type': currencyType,
      'pickup_preference': pickupPreference.apiValue,
      'terms_accepted': '$termsAccepted',
    }, filePath: photoPath);
    return Good.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Good> update(
    int id, {
    String? fromCity,
    String? toCity,
    String? itemDescription,
    String? receiverEmail,
    double? weightKg,
    double? offeredReward,
    String? currencyType,
    PickupMethod? pickupPreference,
    String? photoPath,
  }) async {
    final response = await _client.patchMultipart(
      '/goods/$id',
      {
        if (fromCity != null) 'from_city': fromCity,
        if (toCity != null) 'to_city': toCity,
        if (itemDescription != null) 'item_description': itemDescription,
        if (receiverEmail != null) 'receiver_email': receiverEmail,
        if (weightKg != null) 'weight_kg': '$weightKg',
        if (offeredReward != null) 'offered_reward': '$offeredReward',
        if (currencyType != null) 'currency_type': currencyType,
        if (pickupPreference != null)
          'pickup_preference': pickupPreference.apiValue,
      },
      filePath: photoPath,
      fileField: 'photo',
    );
    return Good.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete('/goods/$id');
}
