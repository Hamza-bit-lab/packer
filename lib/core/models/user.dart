enum IdVerificationStatus { none, pending, approved, rejected }

IdVerificationStatus _idVerificationStatusFromString(String? value) {
  return switch (value) {
    'pending' => IdVerificationStatus.pending,
    'approved' => IdVerificationStatus.approved,
    'rejected' => IdVerificationStatus.rejected,
    _ => IdVerificationStatus.none,
  };
}

class User {
  User({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.country,
    required this.profilePicUrl,
    required this.averageRating,
    required this.totalReviews,
    this.completedDeliveriesCount = 0,
    this.emailVerified = false,
    this.createdAt,
    this.idVerificationStatus = IdVerificationStatus.none,
    this.idVerifiedPublic = false,
    this.isOnline = false,
    this.lastSeenAt,
    this.notifyBookings = true,
    this.notifyMessages = true,
    this.notifyRouteAlerts = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      country: json['country'] as String?,
      profilePicUrl: json['profile_pic_url'] as String?,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['total_reviews'] as int? ?? 0,
      completedDeliveriesCount: json['completed_deliveries_count'] as int? ?? 0,
      emailVerified: json['email_verified'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      // `/me` sends the full status; public profiles only send `id_verified`.
      idVerificationStatus: _idVerificationStatusFromString(
        json['id_verification_status'] as String?,
      ),
      idVerifiedPublic: json['id_verified'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeenAt: json['last_seen_at'] == null
          ? null
          : DateTime.parse(json['last_seen_at'] as String),
      notifyBookings: json['notify_bookings'] as bool? ?? true,
      notifyMessages: json['notify_messages'] as bool? ?? true,
      notifyRouteAlerts: json['notify_route_alerts'] as bool? ?? true,
    );
  }

  /// Round-trips with [User.fromJson]; used to cache the signed-in user.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'country': country,
      'profile_pic_url': profilePicUrl,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'completed_deliveries_count': completedDeliveriesCount,
      'email_verified': emailVerified,
      'created_at': createdAt?.toIso8601String(),
      'id_verification_status': idVerificationStatus.name,
      'id_verified': idVerifiedPublic,
      'is_online': isOnline,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'notify_bookings': notifyBookings,
      'notify_messages': notifyMessages,
      'notify_route_alerts': notifyRouteAlerts,
    };
  }

  final int id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? country;
  final String? profilePicUrl;
  final double averageRating;
  final int totalReviews;
  final int completedDeliveriesCount;
  final bool emailVerified;
  final DateTime? createdAt;
  final IdVerificationStatus idVerificationStatus;
  final bool idVerifiedPublic;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final bool notifyBookings;
  final bool notifyMessages;
  final bool notifyRouteAlerts;

  /// True for both the full status and the public yes/no flag.
  bool get isIdVerified =>
      idVerificationStatus == IdVerificationStatus.approved || idVerifiedPublic;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
