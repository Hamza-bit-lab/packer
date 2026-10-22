import 'good.dart';
import 'trip.dart';
import 'user.dart';

enum BookingStatus {
  pending,
  accepted,
  inTransit,
  arrivedAtDestination,
  completed,
  rejected,
  cancelled,
}

BookingStatus _statusFromString(String value) {
  return switch (value) {
    'in_transit' => BookingStatus.inTransit,
    'arrived_at_destination' => BookingStatus.arrivedAtDestination,
    _ => BookingStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => BookingStatus.pending,
    ),
  };
}

enum Payer { sender, receiver }

Payer _payerFromString(String value) =>
    value == 'receiver' ? Payer.receiver : Payer.sender;

class Booking {
  Booking({
    required this.id,
    required this.status,
    required this.estimatedCost,
    required this.payer,
    required this.trip,
    required this.good,
    required this.sender,
    required this.traveler,
    required this.senderPhoneNumber,
    required this.travelerPhoneNumber,
    required this.inspectionConfirmedAt,
    this.deliveryProofPhotoUrl,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      status: _statusFromString(json['status'] as String),
      estimatedCost: (json['estimated_cost'] as num).toDouble(),
      payer: _payerFromString(json['payer'] as String? ?? 'sender'),
      trip: Trip.fromJson(json['trip'] as Map<String, dynamic>),
      good: Good.fromJson(json['good'] as Map<String, dynamic>),
      sender: User.fromJson(json['sender'] as Map<String, dynamic>),
      traveler: User.fromJson(json['traveler'] as Map<String, dynamic>),
      senderPhoneNumber: json['sender_phone_number'] as String?,
      travelerPhoneNumber: json['traveler_phone_number'] as String?,
      inspectionConfirmedAt: json['inspection_confirmed_at'] == null
          ? null
          : DateTime.parse(json['inspection_confirmed_at'] as String),
      deliveryProofPhotoUrl: json['delivery_proof_photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final BookingStatus status;
  final double estimatedCost;
  final Payer payer;
  final Trip trip;
  final Good good;
  final User sender;
  final User traveler;
  final String? senderPhoneNumber;
  final String? travelerPhoneNumber;
  final DateTime? inspectionConfirmedAt;
  final String? deliveryProofPhotoUrl;
  final DateTime createdAt;

  bool isMineAsSender(int userId) => sender.id == userId;

  bool isMineAsTraveler(int userId) => traveler.id == userId;
}
