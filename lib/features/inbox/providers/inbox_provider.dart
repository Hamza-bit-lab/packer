import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/message_repository.dart';

/// Polls the unread message count for the Inbox badge.
class InboxProvider extends ChangeNotifier {
  InboxProvider(ApiClient client) : _repository = MessageRepository(client);

  static const _pollInterval = Duration(seconds: 15);

  final MessageRepository _repository;
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
