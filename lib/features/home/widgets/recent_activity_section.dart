import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/booking.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton.dart';
import '../../auth/providers/auth_provider.dart';
import '../../bookings/screens/booking_detail_screen.dart';
import '../../bookings/screens/history_screen.dart';
import '../../bookings/widgets/booking_status_badge.dart';
import '../../feed/widgets/user_avatar.dart';

const _maxRecentItems = 5;

/// Home's Recent Activity list; reuses bookings from [HomeScreen].
class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key, required this.bookings});

  /// Null while [HomeScreen] is still loading.
  final List<Booking>? bookings;

  void _openHistory(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthProvider>().user?.id;
    final recent = bookings == null
        ? null
        : pastBookingsSortedByRecency(bookings!).take(_maxRecentItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Activity',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _openHistory(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View all',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recent == null)
          const SkeletonListTiles(count: 3)
        else if (recent.isEmpty)
          const _EmptyActivityRow()
        else
          for (final booking in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecentActivityRow(
                booking: booking,
                isTraveler: booking.traveler.id == myId,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BookingDetailScreen(bookingId: booking.id),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _EmptyActivityRow extends StatelessWidget {
  const _EmptyActivityRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: AppColors.textSecondary, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No recent activity yet. Completed shipments will show up here.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  const _RecentActivityRow({
    required this.booking,
    required this.isTraveler,
    required this.onTap,
  });

  final Booking booking;
  final bool isTraveler;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final otherParty = isTraveler ? booking.sender : booking.traveler;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.tile),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.tile),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.tile),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              UserAvatar(user: otherParty, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherParty.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${booking.trip.fromCity} → ${booking.trip.toCity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              BookingStatusBadge(status: booking.status),
            ],
          ),
        ),
      ),
    );
  }
}
