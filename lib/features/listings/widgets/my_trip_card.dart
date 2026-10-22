import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/models/trip.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_pill.dart';
import '../../feed/widgets/date_format.dart';
import '../../feed/widgets/route_row.dart';

/// My Trips card on My Posts; route-led, with a views count.
class MyTripCard extends StatelessWidget {
  const MyTripCard({
    super.key,
    required this.trip,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Very faint brand tint to lift the card off the background.
  static const _tint = Color(0x0AFF5A46);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _tint,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RouteRow(
                      fromCity: trip.fromCity,
                      toCity: trip.toCity,
                      background: _tint,
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Departs ${formatShortDate(trip.departureDateTime)} · ${trip.airlineName}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trip.photoUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: trip.photoUrl!,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusPill(
                    icon: Icons.scale_outlined,
                    label: '${trip.maxWeightKg.toStringAsFixed(0)} kg free',
                    color: AppColors.textSecondary,
                  ),
                  StatusPill(
                    icon: trip.pickupMethod == PickupMethod.travelerPicksUp
                        ? Icons.luggage_outlined
                        : Icons.outbox_outlined,
                    label: trip.pickupMethod == PickupMethod.travelerPicksUp
                        ? 'You collect'
                        : 'Drop-off',
                    color: AppColors.textSecondary,
                  ),
                  StatusPill(
                    icon: trip.deliveryMethod == DeliveryMethod.travelerDelivers
                        ? Icons.delivery_dining_rounded
                        : Icons.storefront_outlined,
                    label:
                        trip.deliveryMethod == DeliveryMethod.travelerDelivers
                        ? 'You deliver'
                        : 'They pick up',
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: trip.ratePerKg.toStringAsFixed(0),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        TextSpan(
                          text: ' ${trip.currencyType}/kg',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.visibility_outlined,
                    color: AppColors.textTertiary,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trip.viewsCount == 1
                        ? '1 view'
                        : '${trip.viewsCount} views',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
