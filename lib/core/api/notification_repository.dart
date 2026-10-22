import '../models/app_notification.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'feed_repository.dart' show PagedResult;

class NotificationRepository {
  NotificationRepository(this._client);

  final ApiClient _client;

  Future<PagedResult<AppNotification>> fetchMine({int page = 1}) async {
    final response = await _client.get('/notifications?per_page=20&page=$page');
    final items = (response['data'] as List)
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
    final meta = response['meta'] as Map<String, dynamic>?;
    final currentPage = meta?['current_page'] as int? ?? 1;
    final lastPage = meta?['last_page'] as int? ?? 1;
    return PagedResult(items: items, hasMore: currentPage < lastPage);
  }

  Future<int> unreadCount() async {
    final response = await _client.get('/notifications/unread-count');
    return response['unread_count'] as int? ?? 0;
  }

  Future<void> markRead(String id) =>
      _client.post('/notifications/$id/read', {});

  Future<void> markAllRead() => _client.post('/notifications/read-all', {});

  /// Which notification categories the user wants (in-app and push).
  Future<User> updatePreferences({
    bool? notifyBookings,
    bool? notifyMessages,
    bool? notifyRouteAlerts,
  }) async {
    final response = await _client.patch('/notification-preferences', {
      if (notifyBookings != null) 'notify_bookings': notifyBookings,
      if (notifyMessages != null) 'notify_messages': notifyMessages,
      if (notifyRouteAlerts != null) 'notify_route_alerts': notifyRouteAlerts,
    });
    return User.fromJson(response['data'] as Map<String, dynamic>);
  }
}
