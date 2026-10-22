import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/booking_repository.dart';
import '../../../core/api/notification_repository.dart';
import '../../../core/models/booking.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/verify_email_screen.dart';
import '../../bookings/screens/bookings_screen.dart';
import '../../bookings/screens/history_screen.dart';
import '../../feed/screens/feed_screen.dart';
import '../../feedback/screens/feature_requests_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
// Go Premium — on hold, re-enable later:
// import '../../premium/widgets/go_premium_banner.dart';
import '../widgets/featured_travelers_section.dart';
import '../widgets/recent_activity_section.dart';

const _activeStatuses = {
  BookingStatus.pending,
  BookingStatus.accepted,
  BookingStatus.inTransit,
  BookingStatus.arrivedAtDestination,
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Fetched once here and shared with RecentActivitySection.
  List<Booking>? _bookings;
  int _routeAlertMatchCount = 0;
  String? _routeAlertMatchBody;

  int? get _activeShipmentsCount =>
      _bookings?.where((b) => _activeStatuses.contains(b.status)).length;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _loadRouteAlertMatches();
  }

  Future<void> _loadBookings() async {
    try {
      final bookings = await BookingRepository(
        context.read<AuthProvider>().client,
      ).fetchMine();
      if (mounted) {
        setState(() => _bookings = bookings);
      }
    } catch (_) {
      // Home screen stays useful even if this one summary fails to load.
    }
  }

  Future<void> _loadRouteAlertMatches() async {
    try {
      final notifications = await NotificationRepository(
        context.read<AuthProvider>().client,
      ).fetchMine();
      final matches = notifications.items
          .where((n) => n.isUnread && n.type == 'route_alert_matched')
          .toList();
      if (mounted) {
        setState(() {
          _routeAlertMatchCount = matches.length;
          _routeAlertMatchBody = matches.length == 1
              ? matches.first.body
              : null;
        });
      }
    } catch (_) {
      // Home screen stays useful even if this one summary fails to load.
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${user?.name ?? ''}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (user?.country != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                                size: 15,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                user!.country!,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: AppColors.primarySoft,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FeatureRequestsScreen(),
                        ),
                      ),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.lightbulb_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                  children: [
                    const TextSpan(text: 'Find the Perfect '),
                    TextSpan(
                      text: 'Traveler',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    const TextSpan(text: ' for Your Delivery!'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.tile),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.tile),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const FeedScreen(type: FeedType.travelers),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.tile),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.subtle,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Search trips & items',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                              AppRadii.button,
                            ),
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            color: AppColors.onPrimary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Go Premium — on hold, re-enable later:
              // const SizedBox(height: 18),
              // const GoPremiumBanner(),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.flight_takeoff_rounded,
                      label: 'Send Item',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const FeedScreen(type: FeedType.travelers),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.inventory_2_rounded,
                      label: 'Carry & Earn',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const FeedScreen(type: FeedType.goods),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.local_shipping_rounded,
                      label: 'Shipments',
                      badgeCount: _activeShipmentsCount,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BookingsScreen(),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.history_rounded,
                      label: 'History',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HistoryScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_routeAlertMatchCount > 0) ...[
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.travel_explore_rounded,
                  label:
                      _routeAlertMatchBody ??
                      '$_routeAlertMatchCount new matches on your saved routes',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
              ],
              if (user != null && !user.emailVerified) ...[
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.mark_email_unread_outlined,
                  label: 'Verify your email to build trust',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const VerifyEmailScreen(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              const FeaturedTravelersSection(),
              const SizedBox(height: 26),
              RecentActivitySection(bookings: _bookings),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.tile),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.tile),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.tile),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.subtle,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick-action icon in the 4-across row under the search bar.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  // `ink` adapts to dark mode; literal black would disappear.
                  child: Icon(icon, color: AppColors.ink, size: 26),
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.background,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
