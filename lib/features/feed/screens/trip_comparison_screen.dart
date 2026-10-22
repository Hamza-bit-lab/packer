import 'package:flutter/material.dart';

import '../../../core/models/trip.dart';
import '../../../core/theme/app_theme.dart';
import '../../trips/screens/trip_detail_screen.dart';
import '../widgets/date_format.dart';
import '../widgets/user_avatar.dart';

/// Side-by-side comparison of trips on the same route.
class TripComparisonScreen extends StatelessWidget {
  const TripComparisonScreen({super.key, required this.trips});

  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Compare ${trips.length} Trips')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: trips.map((trip) => _TripColumn(trip: trip)).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _TripColumn extends StatelessWidget {
  const _TripColumn({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(user: trip.traveler, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  trip.traveler.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Stat(
            label: 'Price',
            value:
                '${trip.ratePerKg.toStringAsFixed(0)} ${trip.currencyType}/kg',
            highlight: true,
          ),
          _Stat(
            label: 'Rating',
            value:
                '${trip.traveler.averageRating.toStringAsFixed(1)} ★ (${trip.traveler.totalReviews})',
          ),
          _Stat(
            label: 'Deliveries',
            value: '${trip.traveler.completedDeliveriesCount} completed',
          ),
          _Stat(
            label: 'Free weight',
            value: '${trip.maxWeightKg.toStringAsFixed(1)} kg',
          ),
          _Stat(
            label: 'Departs',
            value: formatShortDate(trip.departureDateTime),
          ),
          _Stat(label: 'Delivery', value: trip.deliveryMethod.label),
          _Stat(label: 'Airline', value: trip.airlineName),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: const Text('View & Request'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.primary : AppColors.textPrimary,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              fontSize: highlight ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
