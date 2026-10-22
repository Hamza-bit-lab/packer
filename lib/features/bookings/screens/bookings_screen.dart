import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/api/booking_repository.dart';
import '../../../core/api/rating_repository.dart';
import '../../../core/models/booking.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/segmented_pill_toggle.dart';
import '../../../core/widgets/skeleton.dart';
import '../../auth/providers/auth_provider.dart';
import '../../legal/safety_disclaimer.dart';
import '../widgets/booking_card.dart';
import '../widgets/rate_user_dialog.dart';

const _kFilterLabels = ['All', 'Pending', 'Active', 'Done'];

bool _matchesFilter(Booking booking, int filterIndex) {
  return switch (filterIndex) {
    1 => booking.status == BookingStatus.pending,
    2 => const {
      BookingStatus.accepted,
      BookingStatus.inTransit,
      BookingStatus.arrivedAtDestination,
    }.contains(booking.status),
    3 => const {
      BookingStatus.completed,
      BookingStatus.rejected,
      BookingStatus.cancelled,
    }.contains(booking.status),
    _ => true,
  };
}

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _loadingBookingId;
  int _filterIndex = 0;

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
      _bookings = await BookingRepository(auth.client).fetchMine();
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Could not load your bookings. Pull down to try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handle(
    int bookingId,
    Future<Booking> Function(BookingRepository) action,
  ) async {
    setState(() => _loadingBookingId = bookingId);

    try {
      final auth = context.read<AuthProvider>();
      final updated = await action(BookingRepository(auth.client));
      if (!mounted) return;
      setState(() {
        _bookings = [
          for (final booking in _bookings)
            if (booking.id == bookingId) updated else booking,
        ];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingBookingId = null);
    }
  }

  /// Accepting is gated on the safety confirmation.
  Future<void> _acceptBooking(int bookingId) async {
    final agreed = await SafetyDisclaimerDialog.confirm(context);
    if (!agreed || !mounted) return;
    await _handle(bookingId, (repo) => repo.accept(bookingId));
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm delivery'),
        content: const Text(
          'Before marking this as delivered, make sure the sender has had the chance to inspect the contents in person. '
          "You'll need to attach a photo as proof of delivery. Continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final XFile? photo;
    try {
      photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open the camera: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (photo == null) return;

    final proofPhotoPath = photo.path;
    _handle(
      booking.id,
      (repo) => repo.complete(booking.id, proofPhotoPath: proofPhotoPath),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Shipments')),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: SegmentedPillToggle(
                labels: _kFilterLabels,
                selectedIndex: _filterIndex,
                onChanged: (index) => setState(() => _filterIndex = index),
              ),
            ),
            Expanded(child: _buildBody(myId)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(int? myId) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: SkeletonCards(count: 3, cardHeight: 220),
      );
    }

    if (_errorMessage != null && _bookings.isEmpty) {
      return _MessageView(message: _errorMessage!, onRetry: _load);
    }

    if (_bookings.isEmpty) {
      return _MessageView(
        message:
            'No shipments yet. Find a traveler or an item from the Home tab to get started.',
        onRetry: _load,
      );
    }

    final visible = _bookings
        .where((booking) => _matchesFilter(booking, _filterIndex))
        .toList();

    if (visible.isEmpty) {
      return _MessageView(
        message: 'Nothing in "${_kFilterLabels[_filterIndex]}" right now.',
        onRetry: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final booking = visible[index];
          final isTraveler = booking.traveler.id == myId;
          final otherPartyName = isTraveler
              ? booking.sender.name
              : booking.traveler.name;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: BookingCard(
              booking: booking,
              currentUserId: myId ?? -1,
              isActionLoading: _loadingBookingId == booking.id,
              onAccept: () => _acceptBooking(booking.id),
              onReject: () =>
                  _handle(booking.id, (repo) => repo.reject(booking.id)),
              onMarkInTransit: () =>
                  _handle(booking.id, (repo) => repo.markInTransit(booking.id)),
              onMarkArrived: () =>
                  _handle(booking.id, (repo) => repo.markArrived(booking.id)),
              onCancel: () =>
                  _handle(booking.id, (repo) => repo.cancel(booking.id)),
              onComplete: () => _confirmComplete(booking),
              onRate: () => _rate(booking, otherPartyName),
            ),
          );
        },
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
              Icons.receipt_long_outlined,
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
