import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/good_repository.dart';
import '../../../core/api/notification_repository.dart';
import '../../../core/api/profile_repository.dart';
import '../../../core/api/trip_repository.dart';
import '../../../core/models/app_notification.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../auth/providers/auth_provider.dart';
import '../../bookings/screens/booking_detail_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../feed/widgets/date_format.dart';
import '../../feedback/screens/feature_requests_screen.dart';
import '../../goods/screens/good_detail_screen.dart';
import '../../profile/screens/id_verification_screen.dart';
import '../../trips/screens/trip_detail_screen.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationRepository _repository;
  final List<AppNotification> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _errorMessage;
  String? _openingNotificationId;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _repository = NotificationRepository(context.read<AuthProvider>().client);
    _load();
  }

  Future<void> _load({bool reset = true}) async {
    setState(() {
      if (reset) {
        _isLoading = true;
        _page = 1;
      } else {
        _isLoadingMore = true;
      }
      _errorMessage = null;
    });

    try {
      final result = await _repository.fetchMine(page: _page);
      if (!mounted) return;
      setState(() {
        if (reset) _notifications.clear();
        // Message notifications are in the Inbox tab, so excluded here.
        _notifications.addAll(
          result.items.where((n) => n.type != 'new_message'),
        );
        _hasMore = result.hasMore;
      });
      if (reset) {
        // Only the first page needs this — it marks every unread
        // notification as read server-side, not just this page's.
        await _repository.markAllRead();
        if (mounted) context.read<NotificationProvider>().clear();
      }
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Could not load notifications. Pull down to try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _page += 1;
    await _load(reset: false);
  }

  Future<void> _open(AppNotification notification) async {
    if (_openingNotificationId != null) return;

    final auth = context.read<AuthProvider>();
    setState(() => _openingNotificationId = notification.id);

    try {
      if (notification.bookingId != null) {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                BookingDetailScreen(bookingId: notification.bookingId!),
          ),
        );
        return;
      }

      if (notification.tripId != null) {
        final trip = await TripRepository(
          auth.client,
        ).fetchOne(notification.tripId!);
        if (!mounted) return;
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)));
        return;
      }

      if (notification.goodId != null) {
        final good = await GoodRepository(
          auth.client,
        ).fetchOne(notification.goodId!);
        if (!mounted) return;
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => GoodDetailScreen(good: good)));
        return;
      }

      if (notification.senderId != null) {
        final otherParty = await ProfileRepository(
          auth.client,
        ).fetchPublicProfile(notification.senderId!);
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChatScreen(otherParty: otherParty)),
        );
        return;
      }

      if (notification.type == 'feature_request_status' ||
          notification.type == 'feature_request_votes') {
        if (!mounted) return;
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const FeatureRequestsScreen()));
        return;
      }

      // An ID verification review has a fixed destination, no id needed.
      if (notification.type == 'id_verification_reviewed') {
        if (!mounted) return;
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const IdVerificationScreen()));
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _openingNotificationId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: SectionHeader(title: 'Notifications'),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SkeletonListTiles(count: 6),
      );
    }

    if (_errorMessage != null && _notifications.isEmpty) {
      return _MessageView(message: _errorMessage!, onRetry: _load);
    }

    if (_notifications.isEmpty) {
      return _MessageView(
        message: "You're all caught up — no notifications yet.",
        onRetry: _load,
      );
    }

    final unread = _notifications.where((n) => n.isUnread).toList();
    final read = _notifications.where((n) => !n.isUnread).toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (unread.isNotEmpty) ...[
            const _SectionLabel('New'),
            for (final notification in unread)
              _NotificationRow(
                notification: notification,
                isOpening: _openingNotificationId == notification.id,
                onTap: () => _open(notification),
              ),
          ],
          if (read.isNotEmpty) ...[
            _SectionLabel('Earlier', topPadding: unread.isNotEmpty ? 12 : 0),
            for (final notification in read)
              _NotificationRow(
                notification: notification,
                isOpening: _openingNotificationId == notification.id,
                onTap: () => _open(notification),
              ),
          ],
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (_isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_hasMore) {
      return Center(
        child: TextButton(onPressed: _loadMore, child: const Text('Load more')),
      );
    }

    return const SizedBox.shrink();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {this.topPadding = 0});

  final String label;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 8),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w800,
          fontSize: 13.5,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

/// Notification row: avatar with type icon badge, text, time, unread dot.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.isOpening,
    required this.onTap,
  });

  final AppNotification notification;
  final bool isOpening;
  final VoidCallback onTap;

  static Color _colorFor(String type) {
    return switch (type) {
      'booking_requested' => AppColors.warning,
      'booking_accepted' => AppColors.success,
      'booking_rejected' => AppColors.error,
      'booking_cancelled' => AppColors.error,
      'booking_in_transit' => AppColors.primary,
      'booking_arrived' => AppColors.primary,
      'booking_completed' => AppColors.success,
      'new_rating' => AppColors.warning,
      'route_alert_matched' => AppColors.primary,
      'matching_route_listing' => AppColors.primary,
      'listing_removed' => AppColors.error,
      'feature_request_status' => AppColors.success,
      'feature_request_votes' => AppColors.primary,
      'report_resolved' => AppColors.info,
      'admin_alert' => AppColors.warning,
      'id_verification_reviewed' => const Color(0xFFA78BFA),
      'new_message' => const Color(0xFFA78BFA),
      _ => AppColors.textSecondary,
    };
  }

  static IconData _iconFor(String type) {
    return switch (type) {
      'booking_requested' => Icons.inventory_2_rounded,
      'booking_accepted' => Icons.check_rounded,
      'booking_rejected' => Icons.close_rounded,
      'booking_cancelled' => Icons.close_rounded,
      'booking_in_transit' => Icons.flight_takeoff_rounded,
      'booking_arrived' => Icons.flight_land_rounded,
      'booking_completed' => Icons.local_shipping_rounded,
      'new_rating' => Icons.star_rounded,
      'route_alert_matched' => Icons.notifications_active_rounded,
      'matching_route_listing' => Icons.route_rounded,
      'listing_removed' => Icons.remove_circle_rounded,
      'feature_request_status' => Icons.lightbulb_rounded,
      'feature_request_votes' => Icons.thumb_up_rounded,
      'report_resolved' => Icons.flag_rounded,
      'admin_alert' => Icons.admin_panel_settings_rounded,
      'id_verification_reviewed' => Icons.shield_rounded,
      'new_message' => Icons.chat_bubble_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final rowColor = notification.isUnread
        ? AppColors.primarySoft
        : Colors.transparent;
    final badgeColor = _colorFor(notification.type);
    final badgeBorderColor = notification.isUnread
        ? AppColors.primarySoft
        : AppColors.background;
    // Gold needs dark icon content; other badge colors use white.
    final onBadgeColor = badgeColor == AppColors.primary
        ? AppColors.onPrimary
        : Colors.white;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: rowColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surfaceMuted,
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.textTertiary,
                    size: 26,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: badgeBorderColor, width: 2.5),
                    ),
                    child: isOpening
                        ? SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: onBadgeColor,
                            ),
                          )
                        : Icon(
                            _iconFor(notification.type),
                            color: onBadgeColor,
                            size: 12,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: notification.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                        TextSpan(
                          text: ' ${notification.body}',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatLastSeen(notification.createdAt),
                    style: TextStyle(
                      color: notification.isUnread
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (notification.isUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
