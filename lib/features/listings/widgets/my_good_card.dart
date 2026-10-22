import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/models/good.dart';
import '../../../core/models/trip.dart' show PickupMethod;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_pill.dart';
import '../../feed/widgets/route_row.dart';

/// My Items card on My Posts; mirrors [MyTripCard].
class MyGoodCard extends StatelessWidget {
  const MyGoodCard({
    super.key,
    required this.good,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Good good;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
                      fromCity: good.fromCity,
                      toCity: good.toCity,
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
                good.itemDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (good.photoUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: good.photoUrl!,
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
                    label: '${good.weightKg.toStringAsFixed(1)} kg',
                    color: AppColors.textSecondary,
                  ),
                  StatusPill(
                    icon: good.pickupPreference == PickupMethod.senderDelivers
                        ? Icons.outbox_outlined
                        : Icons.luggage_outlined,
                    label: good.pickupPreference == PickupMethod.senderDelivers
                        ? 'You deliver'
                        : 'They collect',
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
                          text: 'Reward ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${good.offeredReward.toStringAsFixed(0)} ${good.currencyType}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
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
                    good.viewsCount == 1
                        ? '1 view'
                        : '${good.viewsCount} views',
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
