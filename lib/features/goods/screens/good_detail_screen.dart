import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/booking_repository.dart';
import '../../../core/api/good_repository.dart';
import '../../../core/api/trip_repository.dart';
import '../../../core/models/booking.dart';
import '../../../core/models/good.dart';
import '../../../core/models/trip.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/contact_actions.dart';
import '../../../core/widgets/detail_photo_box.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/screens/chat_screen.dart';
import '../../feed/widgets/route_row.dart';
import '../../feed/widgets/user_avatar.dart';
import '../../feed/widgets/verified_badge.dart';
import '../../legal/safety_disclaimer.dart';
import '../../profile/screens/public_profile_screen.dart';
import '../../trips/screens/trip_form_screen.dart';
import 'good_form_screen.dart';

/// Faint brand tint, same as My Posts cards and Trip Details.
const _cardTint = Color(0x0AFF5A46);

class GoodDetailScreen extends StatefulWidget {
  const GoodDetailScreen({super.key, required this.good});

  final Good good;

  @override
  State<GoodDetailScreen> createState() => _GoodDetailScreenState();
}

class _GoodDetailScreenState extends State<GoodDetailScreen> {
  bool _isOffering = false;

  // A just-posted trip already passed the safety confirmation in its form.
  bool _pickedNewTrip = false;

  @override
  void initState() {
    super.initState();
    _registerView();
  }

  /// Fires `GET /goods/{id}` in the background just to count a view.
  Future<void> _registerView() async {
    try {
      await GoodRepository(
        context.read<AuthProvider>().client,
      ).fetchOne(widget.good.id);
    } catch (_) {
      // Not user-visible — a failed view ping shouldn't affect this screen.
    }
  }

  Future<void> _offerToCarry() async {
    final auth = context.read<AuthProvider>();
    final myTrip = await _pickMyTrip(auth);
    if (myTrip == null || !mounted) return;

    final payer = await _pickPayer();
    if (payer == null) return;

    if (!mounted) return;
    final agreed =
        _pickedNewTrip || await SafetyDisclaimerDialog.confirm(context);
    if (!agreed || !mounted) return;

    setState(() => _isOffering = true);

    try {
      await BookingRepository(
        auth.client,
      ).create(tripId: myTrip.id, goodId: widget.good.id, payer: payer);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Offer sent! Check the Bookings tab for updates.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not send offer: ${e.toString().replaceFirst('ApiException: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isOffering = false);
    }
  }

  Future<Payer?> _pickPayer() async {
    return showDialog<Payer>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Who pays for this trip?'),
        content: const Text(
          'Choose who is responsible for paying the estimated cost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(Payer.sender),
            child: const Text('Sender will'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(Payer.receiver),
            child: const Text('Receiver will'),
          ),
        ],
      ),
    );
  }

  Future<Trip?> _pickMyTrip(AuthProvider auth) async {
    final myTrips = await TripRepository(auth.client).fetchMine(auth.user!.id);

    if (!mounted) return null;

    final picked = await showModalBottomSheet<Trip>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _TripPickerSheet(trips: myTrips, good: widget.good),
    );
    _pickedNewTrip = picked != null && !myTrips.any((t) => t.id == picked.id);
    return picked;
  }

  Future<void> _editGood() async {
    final saved = await Navigator.of(context).push<Good>(
      MaterialPageRoute(builder: (_) => GoodFormScreen(good: widget.good)),
    );
    // The form already saved the edit server-side; just back out to My Posts
    // so the caller's list reloads with the fresh copy.
    if (saved != null && mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteGood() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this item?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await GoodRepository(
        context.read<AuthProvider>().client,
      ).delete(widget.good.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not delete this item.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final good = widget.good;
    final myId = context.read<AuthProvider>().user?.id;
    final isMyOwnGood = myId == good.sender.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _buildBody(good, isMyOwnGood)),
            isMyOwnGood ? _buildOwnerBar() : _buildOfferBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Good good, bool isMyOwnGood) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PublicProfileScreen(userId: good.sender.id),
              ),
            ),
            child: Row(
              children: [
                UserAvatar(user: good.sender, size: 52),
                const SizedBox(width: 14),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          if (good.sender.emailVerified) ...[
                            const SizedBox(width: 6),
                            const VerifiedBadge(size: 17),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${good.sender.averageRating.toStringAsFixed(1)} (${good.sender.totalReviews} reviews)',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
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
          const SizedBox(height: 20),
          DetailPhotoBox(
            photoUrl: good.photoUrl,
            icon: Icons.inventory_2_outlined,
            placeholderLabel: 'No photo added for this item',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardTint,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RouteRow(
                  fromCity: good.fromCity,
                  toCity: good.toCity,
                  background: _cardTint,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 16),
                Text(
                  good.itemDescription,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                _DetailRow(
                  icon: Icons.scale_outlined,
                  label: 'Weight',
                  value: '${good.weightKg.toStringAsFixed(1)} kg',
                ),
                const SizedBox(height: 18),
                _DetailRow(
                  icon: Icons.card_giftcard_outlined,
                  label: 'Offered reward',
                  value:
                      '${good.offeredReward.toStringAsFixed(0)} ${good.currencyType}',
                ),
                const SizedBox(height: 18),
                _DetailRow(
                  icon: good.pickupPreference == PickupMethod.senderDelivers
                      ? Icons.outbox_outlined
                      : Icons.luggage_outlined,
                  label: 'Handover at ${good.fromCity}',
                  value: good.pickupPreference == PickupMethod.senderDelivers
                      ? "Sender delivers it to the traveler"
                      : 'Traveler picks it up from the sender',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (isMyOwnGood)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardTint,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This is your own item',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use the buttons below to edit or remove it.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (good.senderPhoneNumber != null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => callPhoneNumber(good.senderPhoneNumber!),
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: const Text('Call'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => openWhatsAppChat(
                        good.senderPhoneNumber!,
                        message:
                            "Hi ${good.sender.name}, I saw your item from ${good.fromCity} to ${good.toCity} on Packer — I might be able to carry it.",
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      icon: Icon(
                        Icons.chat_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(otherParty: good.sender),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Chat on Packer'),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardTint,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flying this route already?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Post your trip so senders heading the same way can find and request you directly.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TripFormScreen(),
                          ),
                        ),
                        child: const Text('Post a Trip'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fixed bottom bar for the primary action — same bottom-anchored weight
  /// as the form screens, instead of a button that scrolls away.
  Widget _buildOfferBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ElevatedButton(
        onPressed: _isOffering ? null : _offerToCarry,
        child: _isOffering
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.onPrimary,
                ),
              )
            : const Text('Offer to Carry This Item'),
      ),
    );
  }

  /// Bottom bar shown instead of [_buildOfferBar] when viewing your own
  /// item — lets you manage it without going back to My Posts first.
  Widget _buildOwnerBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _editGood,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _deleteGood,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripPickerSheet extends StatelessWidget {
  const _TripPickerSheet({required this.trips, required this.good});

  final List<Trip> trips;
  final Good good;

  Future<void> _postNewTrip(BuildContext context) async {
    final created = await Navigator.of(
      context,
    ).push<Trip>(MaterialPageRoute(builder: (_) => const TripFormScreen()));

    // Newly created: close the sheet so the caller sends the offer.
    if (created != null && context.mounted) {
      Navigator.of(context).pop(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Which trip will carry this item?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              "Pick one of your posted trips, or post a new one for this route.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            if (trips.isNotEmpty) ...[
              Text(
                'Your posted trips',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: trips.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${trip.fromCity} → ${trip.toCity}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${trip.maxWeightKg.toStringAsFixed(1)} kg free · ${trip.ratePerKg.toStringAsFixed(0)} ${trip.currencyType}/kg',
                      ),
                      onTap: () => Navigator.of(context).pop(trip),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
            ],
            OutlinedButton.icon(
              onPressed: () => _postNewTrip(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Post a new trip'),
            ),
          ],
        ),
      ),
    );
  }
}
