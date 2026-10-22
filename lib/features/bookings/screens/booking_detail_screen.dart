import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/booking_repository.dart';
import '../../../core/api/rating_repository.dart';
import '../../../core/models/booking.dart';
import '../../../core/models/trip.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/widgets/date_format.dart';
import '../../legal/safety_disclaimer.dart';
import '../widgets/booking_card.dart';
import '../widgets/delivery_confirmation_flow.dart';
import '../widgets/rate_user_dialog.dart';

/// Single shipment view, opened from a booking notification.
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Booking? _booking;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      _booking = await BookingRepository(
        auth.client,
      ).fetchOne(widget.bookingId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not load this shipment.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handle(
    Future<Booking> Function(BookingRepository) action,
  ) async {
    setState(() => _isActionLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final updated = await action(BookingRepository(auth.client));
      if (!mounted) return;
      setState(() => _booking = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  /// Accepting is gated on the safety confirmation.
  Future<void> _accept() async {
    final agreed = await SafetyDisclaimerDialog.confirm(context);
    if (!agreed || !mounted) return;
    await _handle((repo) => repo.accept(widget.bookingId));
  }

  Future<void> _rate(Booking booking, String otherPartyName) async {
    final result = await showDialog<RatingSubmission>(
      context: context,
      builder: (context) => RateUserDialog(userName: otherPartyName),
    );
    if (result == null || !mounted) return;

    try {
      final auth = context.read<AuthProvider>();
      await RatingRepository(auth.client).rate(
        bookingId: booking.id,
        stars: result.stars,
        comment: result.comment,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Thanks for your feedback!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmComplete(Booking booking) async {
    final result = await confirmDelivery(
      context,
      repository: BookingRepository(context.read<AuthProvider>().client),
      bookingId: booking.id,
    );
    if (result == null) return;

    _handle(
      (repo) => repo.complete(
        booking.id,
        otp: result.otp,
        proofPhotoPath: result.photoPath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Shipment')),
      body: _buildBody(myId),
    );
  }

  Widget _buildBody(int? myId) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final booking = _booking;
    if (booking == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage ?? 'Shipment not found.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final isTraveler = booking.traveler.id == myId;
    final otherPartyName = isTraveler
        ? booking.sender.name
        : booking.traveler.name;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          BookingCard(
            booking: booking,
            currentUserId: myId ?? -1,
            isActionLoading: _isActionLoading,
            onAccept: _accept,
            onReject: () => _handle((repo) => repo.reject(booking.id)),
            onMarkInTransit: () =>
                _handle((repo) => repo.markInTransit(booking.id)),
            onMarkArrived: () =>
                _handle((repo) => repo.markArrived(booking.id)),
            onCancel: () => _handle((repo) => repo.cancel(booking.id)),
            onComplete: () => _confirmComplete(booking),
            onRate: () => _rate(booking, otherPartyName),
          ),
          if (_StatusStepper.appliesTo(booking.status)) ...[
            const SizedBox(height: 16),
            _StatusStepper(status: booking.status),
          ],
          const SizedBox(height: 16),
          _ShipmentDetailsCard(booking: booking),
        ],
      ),
    );
  }
}

/// Full shipment details the compact `BookingCard` lacks.
class _ShipmentDetailsCard extends StatelessWidget {
  const _ShipmentDetailsCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shipment details',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
          ),
          const SizedBox(height: 14),
          Text(
            booking.good.itemDescription,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                icon: Icons.flight_rounded,
                label: booking.trip.airlineName,
                color: AppColors.onLavenderTint,
              ),
              StatusPill(
                icon: Icons.event_outlined,
                label: formatShortDate(booking.trip.departureDateTime),
                color: AppColors.onSkyTint,
              ),
              StatusPill(
                icon: booking.trip.pickupMethod == PickupMethod.travelerPicksUp
                    ? Icons.luggage_outlined
                    : Icons.outbox_outlined,
                label: booking.trip.pickupMethod == PickupMethod.travelerPicksUp
                    ? 'Traveler collects at pickup'
                    : 'Sender drops off at pickup',
                color: AppColors.onMintTint,
              ),
              StatusPill(
                icon:
                    booking.trip.deliveryMethod ==
                        DeliveryMethod.travelerDelivers
                    ? Icons.delivery_dining_rounded
                    : Icons.storefront_outlined,
                label: booking.trip.deliveryMethod.label,
                color: AppColors.onPeachTint,
              ),
              if (booking.inspectionConfirmedAt != null)
                StatusPill(
                  icon: Icons.fact_check_outlined,
                  label: 'Inspection confirmed',
                  color: AppColors.success,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Requested ${formatShortDate(booking.createdAt)} · #${booking.id}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Vertical stepper for the booking's positive path.
class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.status});

  final BookingStatus status;

  static const _steps = [
    ('Requested', BookingStatus.pending),
    ('Accepted', BookingStatus.accepted),
    ('In transit', BookingStatus.inTransit),
    ('Arrived', BookingStatus.arrivedAtDestination),
    ('Delivered', BookingStatus.completed),
  ];

  static bool appliesTo(BookingStatus status) {
    return status != BookingStatus.rejected &&
        status != BookingStatus.cancelled;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _steps.indexWhere((step) => step.$2 == status);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          for (var i = 0; i < _steps.length; i++)
            _StepRow(
              label: _steps[i].$1,
              done: i < currentIndex,
              current: i == currentIndex,
              isLast: i == _steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.done,
    required this.current,
    required this.isLast,
  });

  final String label;
  final bool done;
  final bool current;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final reached = done || current;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: current ? 12 : 9,
                height: current ? 12 : 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: current
                      ? AppColors.primary
                      : (done ? AppColors.success : AppColors.border),
                  boxShadow: current
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            blurRadius: 0,
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    color: AppColors.border,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                  color: reached
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
