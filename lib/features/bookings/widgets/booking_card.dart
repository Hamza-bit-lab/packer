import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/booking.dart';
import '../../../core/models/user.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_pill.dart';
import '../../chat/screens/chat_screen.dart';
import '../../feed/widgets/route_row.dart';
import '../../feed/widgets/user_avatar.dart';
import 'booking_status_badge.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    required this.currentUserId,
    this.onAccept,
    this.onReject,
    this.onMarkInTransit,
    this.onMarkArrived,
    this.onComplete,
    this.onCancel,
    this.onRate,
    this.isActionLoading = false,
  });

  final Booking booking;
  final int currentUserId;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onMarkInTransit;
  final VoidCallback? onMarkArrived;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final VoidCallback? onRate;
  final bool isActionLoading;

  bool get _isTraveler => booking.traveler.id == currentUserId;

  User get _otherParty => _isTraveler ? booking.sender : booking.traveler;

  String? get _otherPartyPhone =>
      _isTraveler ? booking.senderPhoneNumber : booking.travelerPhoneNumber;

  Future<void> _call() async {
    final phone = _otherPartyPhone;
    if (phone == null) return;
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(otherParty: _otherParty)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              UserAvatar(user: _otherParty),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _otherParty.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _isTraveler ? 'Sender' : 'Traveler',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              BookingStatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          RouteRow(
            fromCity: booking.trip.fromCity,
            toCity: booking.trip.toCity,
          ),
          const SizedBox(height: 10),
          Text(
            booking.good.itemDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(
                label: '${booking.good.weightKg.toStringAsFixed(1)} kg',
                color: AppColors.onSkyTint,
              ),
              StatusPill(
                label: booking.payer == Payer.sender
                    ? 'Sender pays'
                    : 'Receiver pays',
                color: AppColors.onMintTint,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Est. cost',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${booking.estimatedCost.toStringAsFixed(0)} ${booking.trip.currencyType}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (booking.deliveryProofPhotoUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: booking.deliveryProofPhotoUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (_otherPartyPhone != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _call,
                    icon: const Icon(Icons.call_rounded, size: 16),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openChat(context),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Chat'),
                ),
              ),
            ],
          ),
          if (_buildActions() case final actions when actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: actions),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    if (isActionLoading) {
      return [
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ),
        ),
      ];
    }

    final actions = <Widget>[];

    if (booking.status == BookingStatus.pending && _isTraveler) {
      actions.add(
        Expanded(
          child: OutlinedButton(
            onPressed: onReject,
            child: const Text('Reject'),
          ),
        ),
      );
      actions.add(const SizedBox(width: 10));
      actions.add(
        Expanded(
          child: ElevatedButton(
            onPressed: onAccept,
            child: const Text('Accept'),
          ),
        ),
      );
    } else if (booking.status == BookingStatus.pending && !_isTraveler) {
      actions.add(
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            child: const Text('Cancel Request'),
          ),
        ),
      );
    } else if (booking.status == BookingStatus.accepted && _isTraveler) {
      actions.add(
        Expanded(
          child: ElevatedButton(
            onPressed: onMarkInTransit,
            child: const Text('Mark In Transit'),
          ),
        ),
      );
    } else if (booking.status == BookingStatus.inTransit && _isTraveler) {
      actions.add(
        Expanded(
          child: ElevatedButton(
            onPressed: onMarkArrived,
            child: Text('Arrived in ${booking.trip.toCity}'),
          ),
        ),
      );
    } else if (booking.status == BookingStatus.arrivedAtDestination &&
        _isTraveler) {
      actions.add(
        Expanded(
          child: ElevatedButton(
            onPressed: onComplete,
            child: const Text('Mark as Delivered'),
          ),
        ),
      );
    } else if (booking.status == BookingStatus.completed && onRate != null) {
      actions.add(
        Expanded(
          child: OutlinedButton(
            onPressed: onRate,
            child: Text('Rate ${_otherParty.name}'),
          ),
        ),
      );
    }

    return actions;
  }
}
