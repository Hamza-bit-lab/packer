enum RouteAlertWatchType { travelers, goods }

RouteAlertWatchType _watchTypeFromString(String value) {
  return RouteAlertWatchType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => RouteAlertWatchType.travelers,
  );
}

class RouteAlert {
  RouteAlert({
    required this.id,
    required this.watchType,
    required this.fromCity,
    required this.toCity,
    required this.createdAt,
  });

  factory RouteAlert.fromJson(Map<String, dynamic> json) {
    return RouteAlert(
      id: json['id'] as int,
      watchType: _watchTypeFromString(json['watch_type'] as String),
      fromCity: json['from_city'] as String,
      toCity: json['to_city'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final RouteAlertWatchType watchType;
  final String fromCity;
  final String toCity;
  final DateTime createdAt;
}
