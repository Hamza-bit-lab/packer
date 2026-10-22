import '../models/good.dart';
import '../models/trip.dart';
import 'api_client.dart';

class PagedResult<T> {
  PagedResult({required this.items, required this.hasMore});

  final List<T> items;
  final bool hasMore;
}

/// Shared filter/sort options for the Travelers and Goods feeds.
class FeedFilters {
  const FeedFilters({
    this.dateFrom,
    this.dateTo,
    this.minWeight,
    this.maxWeight,
    this.sort,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? minWeight;
  final double? maxWeight;
  final String? sort;

  bool get isActive =>
      dateFrom != null ||
      dateTo != null ||
      minWeight != null ||
      maxWeight != null ||
      sort != null;

  FeedFilters copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    double? minWeight,
    double? maxWeight,
    String? sort,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    bool clearMinWeight = false,
    bool clearMaxWeight = false,
    bool clearSort = false,
  }) {
    return FeedFilters(
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      minWeight: clearMinWeight ? null : (minWeight ?? this.minWeight),
      maxWeight: clearMaxWeight ? null : (maxWeight ?? this.maxWeight),
      sort: clearSort ? null : (sort ?? this.sort),
    );
  }
}

class FeedRepository {
  FeedRepository(this._client);

  final ApiClient _client;

  Future<PagedResult<Trip>> fetchTrips({
    String? fromCity,
    String? toCity,
    int page = 1,
    FeedFilters filters = const FeedFilters(),
  }) async {
    final response = await _client.get(
      _buildPath('travelers', fromCity, toCity, page, filters),
    );
    return _toPagedResult(response, Trip.fromJson);
  }

  Future<PagedResult<Good>> fetchGoods({
    String? fromCity,
    String? toCity,
    int page = 1,
    FeedFilters filters = const FeedFilters(),
  }) async {
    final response = await _client.get(
      _buildPath('goods', fromCity, toCity, page, filters),
    );
    return _toPagedResult(response, Good.fromJson);
  }

  String _buildPath(
    String type,
    String? fromCity,
    String? toCity,
    int page,
    FeedFilters filters,
  ) {
    final query = {
      'type': type,
      'page': '$page',
      if (fromCity != null && fromCity.trim().isNotEmpty)
        'from_city': fromCity.trim(),
      if (toCity != null && toCity.trim().isNotEmpty) 'to_city': toCity.trim(),
      if (filters.dateFrom != null)
        'date_from': filters.dateFrom!.toIso8601String().split('T').first,
      if (filters.dateTo != null)
        'date_to': filters.dateTo!.toIso8601String().split('T').first,
      if (filters.minWeight != null) 'min_weight': '${filters.minWeight}',
      if (filters.maxWeight != null) 'max_weight': '${filters.maxWeight}',
      if (filters.sort != null) 'sort': filters.sort!,
    };

    final queryString = query.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');

    return '/feed?$queryString';
  }

  PagedResult<T> _toPagedResult<T>(
    Map<String, dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final items = (response['data'] as List)
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
    final meta = response['meta'] as Map<String, dynamic>?;
    final currentPage = meta?['current_page'] as int? ?? 1;
    final lastPage = meta?['last_page'] as int? ?? 1;

    return PagedResult(items: items, hasMore: currentPage < lastPage);
  }
}
