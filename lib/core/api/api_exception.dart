class ApiException implements Exception {
  ApiException(this.message, {this.errors = const {}, this.statusCode});

  final String message;
  final Map<String, List<String>> errors;

  /// HTTP status of a failed response; null for network errors/timeouts.
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  String? firstErrorFor(String field) => errors[field]?.first;

  @override
  String toString() => message;
}
