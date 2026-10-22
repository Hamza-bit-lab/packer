import 'package:flutter/material.dart';

import '../../../core/models/booking.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_pill.dart';

class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge({super.key, required this.status});

  final BookingStatus status;

  Color get _color {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.secondary;
      case BookingStatus.accepted:
      case BookingStatus.inTransit:
      case BookingStatus.arrivedAtDestination:
        return AppColors.info;
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        return AppColors.error;
    }
  }

  String get _label {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.inTransit:
        return 'In Transit';
      case BookingStatus.arrivedAtDestination:
        return 'Arrived';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusPill(label: _label, color: _color);
  }
}
