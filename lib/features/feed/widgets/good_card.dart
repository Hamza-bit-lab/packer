import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/models/good.dart';
import '../../../core/models/trip.dart' show PickupMethod;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_pill.dart';
import '../../profile/screens/public_profile_screen.dart';
import 'route_row.dart';
import 'user_avatar.dart';
import 'id_verified_badge.dart';
import 'verified_badge.dart';

class GoodCard extends StatelessWidget {
  const GoodCard({
    super.key,
    required this.good,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Good good;
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
                                  PublicProfileScreen(userId: good.sender.id),
                            ),
                          ),
                          child: Row(
                            children: [
                              UserAvatar(user: good.sender),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            good.sender.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        if (good.sender.emailVerified) ...[
                                          const SizedBox(width: 4),
                                          const VerifiedBadge(),
                                        ],
                                        if (good.sender.isIdVerified) ...[
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
                                          '${good.sender.averageRating.toStringAsFixed(1)} (${good.sender.totalReviews})',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12.5,
                                          ),
                                        ),
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
                        child: StatusPill(
                          icon: Icons.scale_outlined,
                          label: '${good.weightKg.toStringAsFixed(1)} kg',
                          color: AppColors.onSkyTint,
                        ),
                      ),
                    ],
                  ),
                  if (good.photoUrl != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: good.photoUrl!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  RouteRow(fromCity: good.fromCity, toCity: good.toCity),
                  const SizedBox(height: 10),
                  Text(
                    good.itemDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StatusPill(
                    icon: good.pickupPreference == PickupMethod.senderDelivers
                        ? Icons.outbox_outlined
                        : Icons.luggage_outlined,
                    label: good.pickupPreference == PickupMethod.senderDelivers
                        ? 'Sender delivers'
                        : 'You collect',
                    color: AppColors.onPeachTint,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text.rich(
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
