import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/booking_repository.dart';
import '../../../core/models/booking.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/booking_card.dart';
import 'booking_detail_screen.dart';

/// Statuses counted as settled booking history.
const pastBookingStatuses = {
  BookingStatus.completed,
  BookingStatus.rejected,
  BookingStatus.cancelled,
};

/// Settled bookings, newest first.
List<Booking> pastBookingsSortedByRecency(List<Booking> bookings) {
  final past = bookings
      .where((booking) => pastBookingStatuses.contains(booking.status))
      .toList();
  past.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return past;
}

/// Read-only log of settled bookings.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
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
      _bookings = await BookingRepository(auth.client).fetchMine();
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Could not load your history. Pull down to try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(bottom: false, child: _buildBody(myId)),
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

    final past = pastBookingsSortedByRecency(_bookings);

    if (past.isEmpty) {
      return _MessageView(message: 'No past shipments yet.', onRetry: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: past.length,
        itemBuilder: (context, index) {
          final booking = past[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookingDetailScreen(bookingId: booking.id),
                ),
              ),
              child: BookingCard(booking: booking, currentUserId: myId ?? -1),
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
              Icons.history_rounded,
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
