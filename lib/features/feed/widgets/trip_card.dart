import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/models/trip.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_pill.dart';
import '../../profile/screens/public_profile_screen.dart';
import 'date_format.dart';
import 'route_row.dart';
import 'user_avatar.dart';
import 'id_verified_badge.dart';
import 'verified_badge.dart';

class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Trip trip;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  bool get _hasActions => onEdit != null || onDelete != null;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.tile),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.tile),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.tile),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.subtle,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PublicProfileScreen(userId: trip.traveler.id),
                            ),
                          ),
                          child: Row(
                            children: [
                              UserAvatar(user: trip.traveler),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            trip.traveler.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        if (trip.traveler.emailVerified) ...[
                                          const SizedBox(width: 4),
                                          const VerifiedBadge(),
                                        ],
                                        if (trip.traveler.isIdVerified) ...[
                                          const SizedBox(width: 4),
                                          const IdVerifiedBadge(),
                                        ],
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          color: AppColors.secondary,
                                          size: 15,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${trip.traveler.averageRating.toStringAsFixed(1)} (${trip.traveler.totalReviews})',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        if (trip
                                                .traveler
                                                .completedDeliveriesCount >
                                            0) ...[
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.local_shipping_outlined,
                                            color: AppColors.textSecondary,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${trip.traveler.completedDeliveriesCount} delivered',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: _hasActions ? 28 : 0),
                        child: Text(
                          formatShortDate(trip.departureDateTime),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (trip.photoUrl != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: trip.photoUrl!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  RouteRow(fromCity: trip.fromCity, toCity: trip.toCity),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusPill(
                        icon: Icons.flight_rounded,
                        label: trip.airlineName,
                        color: AppColors.onLavenderTint,
                      ),
                      StatusPill(
                        icon: Icons.scale_outlined,
                        label: '${trip.maxWeightKg.toStringAsFixed(0)} kg free',
                        color: AppColors.onMintTint,
                      ),
                      StatusPill(
                        icon: trip.pickupMethod == PickupMethod.travelerPicksUp
                            ? Icons.luggage_outlined
                            : Icons.outbox_outlined,
                        label: trip.pickupMethod == PickupMethod.travelerPicksUp
                            ? 'Collects'
                            : 'Drop-off',
                        color: AppColors.onSkyTint,
                      ),
                      StatusPill(
                        icon:
                            trip.deliveryMethod ==
                                DeliveryMethod.travelerDelivers
                            ? Icons.delivery_dining_rounded
                            : Icons.storefront_outlined,
                        label:
                            trip.deliveryMethod ==
                                DeliveryMethod.travelerDelivers
                            ? 'Delivers'
                            : 'Pickup',
                        color: AppColors.onPeachTint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text.rich(
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
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_hasActions)
          Positioned(
            top: 4,
            right: 4,
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onSelected: (value) {
                if (value == 'edit') onEdit?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                if (onEdit != null)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (onDelete != null)
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
      ],
    );
  }
}
