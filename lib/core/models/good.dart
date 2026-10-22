import 'trip.dart' show PickupMethod, pickupMethodFromString;
import 'user.dart';

class Good {
  Good({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.itemDescription,
    required this.weightKg,
    required this.offeredReward,
    required this.currencyType,
    required this.sender,
    this.senderPhoneNumber,
    this.photoUrl,
    this.viewsCount = 0,
    this.pickupPreference = PickupMethod.senderDelivers,
  });

  factory Good.fromJson(Map<String, dynamic> json) {
    return Good(
      id: json['id'] as int,
      fromCity: json['from_city'] as String,
      toCity: json['to_city'] as String,
      itemDescription: json['item_description'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
      offeredReward: (json['offered_reward'] as num).toDouble(),
      currencyType: json['currency_type'] as String,
      sender: User.fromJson(json['sender'] as Map<String, dynamic>),
      senderPhoneNumber: json['sender_phone_number'] as String?,
      photoUrl: json['photo_url'] as String?,
      viewsCount: json['views_count'] as int? ?? 0,
      pickupPreference: pickupMethodFromString(
        json['pickup_preference'] as String? ?? 'sender_delivers',
      ),
    );
  }

  final int id;
  final String fromCity;
  final String toCity;
  final String itemDescription;
  final double weightKg;
  final double offeredReward;
  final String currencyType;
  final User sender;
  final String? senderPhoneNumber;
  final String? photoUrl;
  final int viewsCount;
  final PickupMethod pickupPreference;
}
