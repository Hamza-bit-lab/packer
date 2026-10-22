import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/notification_repository.dart';

/// Polls the unread notification count for the badge (in-app only).
class NotificationProvider extends ChangeNotifier {
  NotificationProvider(ApiClient client)
    : _repository = NotificationRepository(client);

  static const _pollInterval = Duration(seconds: 20);

  final NotificationRepository _repository;
  Timer? _timer;

  int unreadCount = 0;

  void start() {
    _refresh();
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => _refresh());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _refresh() async {
    try {
      unreadCount = await _repository.unreadCount();
      notifyListeners();
    } catch (_) {
      // Ignore transient network errors — the badge just keeps its last value.
    }
  }

  Future<void> refreshNow() => _refresh();

  void clear() {
    unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
