import 'user.dart';

enum DeliveryMethod { receiverPickup, travelerDelivers }

DeliveryMethod _deliveryMethodFromString(String value) {
  return switch (value) {
    'traveler_delivers' => DeliveryMethod.travelerDelivers,
    _ => DeliveryMethod.receiverPickup,
  };
}

extension DeliveryMethodApi on DeliveryMethod {
  String get apiValue => this == DeliveryMethod.travelerDelivers
      ? 'traveler_delivers'
      : 'receiver_pickup';

  String get label => this == DeliveryMethod.travelerDelivers
      ? "Traveler delivers to you"
      : 'You pick up from traveler';
}

/// Who handles the origin-side handoff (mirror of [DeliveryMethod]).
enum PickupMethod { travelerPicksUp, senderDelivers }

PickupMethod pickupMethodFromString(String value) {
  return switch (value) {
    'sender_delivers' => PickupMethod.senderDelivers,
    _ => PickupMethod.travelerPicksUp,
  };
}

extension PickupMethodApi on PickupMethod {
  String get apiValue => this == PickupMethod.senderDelivers
      ? 'sender_delivers'
      : 'traveler_picks_up';
}

class Trip {
  Trip({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.departureDateTime,
    required this.airlineName,
    required this.maxWeightKg,
    required this.ratePerKg,
    required this.currencyType,
    required this.traveler,
    this.travelerPhoneNumber,
    this.photoUrl,
    this.viewsCount = 0,
    this.deliveryMethod = DeliveryMethod.receiverPickup,
    this.pickupMethod = PickupMethod.travelerPicksUp,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as int,
      fromCity: json['from_city'] as String,
      toCity: json['to_city'] as String,
      departureDateTime: DateTime.parse(json['departure_date_time'] as String),
      airlineName: json['airline_name'] as String,
      maxWeightKg: (json['max_weight_kg'] as num).toDouble(),
      ratePerKg: (json['rate_per_kg'] as num).toDouble(),
      currencyType: json['currency_type'] as String,
      traveler: User.fromJson(json['traveler'] as Map<String, dynamic>),
      travelerPhoneNumber: json['traveler_phone_number'] as String?,
      photoUrl: json['photo_url'] as String?,
      viewsCount: json['views_count'] as int? ?? 0,
      deliveryMethod: _deliveryMethodFromString(
        json['delivery_method'] as String? ?? 'receiver_pickup',
      ),
      pickupMethod: pickupMethodFromString(
        json['pickup_method'] as String? ?? 'traveler_picks_up',
      ),
    );
  }

  final int id;
  final String fromCity;
  final String toCity;
  final DateTime departureDateTime;
  final String airlineName;
  final double maxWeightKg;
  final double ratePerKg;
  final String currencyType;
  final User traveler;
  final String? travelerPhoneNumber;
  final String? photoUrl;
  final int viewsCount;
  final DeliveryMethod deliveryMethod;
  final PickupMethod pickupMethod;
}
