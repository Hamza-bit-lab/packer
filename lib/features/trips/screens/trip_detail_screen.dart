import 'package:cached_network_image/cached_network_image.dart';
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
import '../../auth/providers/auth_provider.dart';
import '../../chat/screens/chat_screen.dart';
import '../../feed/screens/trip_comparison_screen.dart';
import '../../feed/widgets/date_format.dart';
import '../../feed/widgets/route_row.dart';
import '../../feed/widgets/user_avatar.dart';
import '../../feed/widgets/verified_badge.dart';
import '../../goods/screens/good_form_screen.dart';
import '../../legal/safety_disclaimer.dart';
import '../../profile/screens/public_profile_screen.dart';

/// Faint brand tint, same as My Posts cards.
const _cardTint = Color(0x0AFF5A46);

class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key, required this.trip});

  final Trip trip;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  bool _isRequesting = false;

  // A just-posted item already passed the safety confirmation in its form.
  bool _pickedNewItem = false;
  List<Trip> _otherTripsOnRoute = [];

  @override
  void initState() {
    super.initState();
    _loadOtherTripsOnRoute();
    _registerView();
  }

  /// Fires `GET /trips/{id}` in the background just to count a view.
  Future<void> _registerView() async {
    try {
      await TripRepository(
        context.read<AuthProvider>().client,
      ).fetchOne(widget.trip.id);
    } catch (_) {
      // Not user-visible — a failed view ping shouldn't affect this screen.
    }
  }

  Future<void> _loadOtherTripsOnRoute() async {
    try {
      final repository = TripRepository(context.read<AuthProvider>().client);
      final trips = await repository.fetchByRoute(
        fromCity: widget.trip.fromCity,
        toCity: widget.trip.toCity,
      );
      if (!mounted) return;
      setState(
        () => _otherTripsOnRoute = trips
            .where((trip) => trip.id != widget.trip.id)
            .toList(),
      );
    } catch (_) {
      // Comparison is a nice-to-have here — silently skip if it fails to load.
    }
  }

  void _openComparison() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TripComparisonScreen(trips: [widget.trip, ..._otherTripsOnRoute]),
      ),
    );
  }

  Future<void> _requestToShip() async {
    final auth = context.read<AuthProvider>();
    final myGoods = await _pickMyGood(auth);
    if (myGoods == null || !mounted) return;

    final payer = await _pickPayer();
    if (payer == null) return;

    if (!mounted) return;
    final agreed =
        _pickedNewItem || await SafetyDisclaimerDialog.confirm(context);
    if (!agreed || !mounted) return;

    setState(() => _isRequesting = true);

    try {
      await BookingRepository(
        auth.client,
      ).create(tripId: widget.trip.id, goodId: myGoods.id, payer: payer);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Request sent! Check the Bookings tab for updates.',
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
            'Could not send request: ${e.toString().replaceFirst('ApiException: ', '')}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  Future<Payer?> _pickPayer() async {
    return showDialog<Payer>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Who pays the traveler?'),
        content: const Text(
          'Choose who is responsible for paying the estimated cost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(Payer.sender),
            child: const Text('I will (sender)'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(Payer.receiver),
            child: const Text('Receiver will'),
          ),
        ],
      ),
    );
  }

  Future<Good?> _pickMyGood(AuthProvider auth) async {
    final myGoods = await GoodRepository(auth.client).fetchMine(auth.user!.id);

    if (!mounted) return null;

    final picked = await showModalBottomSheet<Good>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _GoodPickerSheet(goods: myGoods, trip: widget.trip),
    );
    _pickedNewItem = picked != null && !myGoods.any((g) => g.id == picked.id);
    return picked;
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final myId = context.read<AuthProvider>().user?.id;
    final isMyOwnTrip = myId == trip.traveler.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PublicProfileScreen(userId: trip.traveler.id),
                ),
              ),
              child: Row(
                children: [
                  UserAvatar(user: trip.traveler, size: 52),
                  const SizedBox(width: 14),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            if (trip.traveler.emailVerified) ...[
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
                              '${trip.traveler.averageRating.toStringAsFixed(1)} (${trip.traveler.totalReviews} reviews)',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (trip.traveler.completedDeliveriesCount > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${trip.traveler.completedDeliveriesCount} deliveries completed',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (trip.photoUrl != null) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: trip.photoUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
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
                    fromCity: trip.fromCity,
                    toCity: trip.toCity,
                    background: _cardTint,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 18),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Departure',
                    value:
                        '${formatShortDate(trip.departureDateTime)}, ${trip.departureDateTime.toLocal().hour}:${trip.departureDateTime.toLocal().minute.toString().padLeft(2, '0')}',
                  ),
                  const SizedBox(height: 18),
                  _DetailRow(
                    icon: Icons.flight_rounded,
                    label: 'Airline',
                    value: trip.airlineName,
                  ),
                  const SizedBox(height: 18),
                  _DetailRow(
                    icon: Icons.scale_outlined,
                    label: 'Weight available',
                    value: '${trip.maxWeightKg.toStringAsFixed(1)} kg',
                  ),
                  const SizedBox(height: 18),
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Rate',
                    value:
                        '${trip.ratePerKg.toStringAsFixed(0)} ${trip.currencyType} / kg',
                  ),
                  const SizedBox(height: 18),
                  _DetailRow(
                    icon: trip.pickupMethod == PickupMethod.travelerPicksUp
                        ? Icons.luggage_outlined
                        : Icons.outbox_outlined,
                    label: 'Pickup at ${trip.fromCity}',
                    value: trip.pickupMethod == PickupMethod.travelerPicksUp
                        ? "Traveler collects it themselves"
                        : 'Sender delivers it to the traveler',
                  ),
                  const SizedBox(height: 18),
                  _DetailRow(
                    icon: trip.deliveryMethod == DeliveryMethod.travelerDelivers
                        ? Icons.delivery_dining_rounded
                        : Icons.storefront_outlined,
                    label: 'Delivery',
                    value: trip.deliveryMethod.label,
                  ),
                ],
              ),
            ),
            if (_otherTripsOnRoute.isNotEmpty) ...[
              const SizedBox(height: 16),
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
                      Icons.compare_arrows_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_otherTripsOnRoute.length} more ${_otherTripsOnRoute.length == 1 ? 'traveler is' : 'travelers are'} also flying ${trip.fromCity} → ${trip.toCity}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Compare their price, timing, space, and rating before choosing.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                            ),
                            onPressed: _openComparison,
                            child: const Text('Compare Prices'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            if (isMyOwnTrip)
              Text(
                'This is your own trip.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              )
            else ...[
              if (trip.travelerPhoneNumber != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            callPhoneNumber(trip.travelerPhoneNumber!),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => openWhatsAppChat(
                          trip.travelerPhoneNumber!,
                          message:
                              "Hi ${trip.traveler.name}, I saw your trip from ${trip.fromCity} to ${trip.toCity} on Packer.",
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
                    builder: (_) => ChatScreen(otherParty: trip.traveler),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Chat on Packer'),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _isRequesting ? null : _requestToShip,
                child: _isRequesting
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Text('Request to Ship an Item'),
              ),
            ],
          ],
        ),
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

class _GoodPickerSheet extends StatelessWidget {
  const _GoodPickerSheet({required this.goods, required this.trip});

  final List<Good> goods;
  final Trip trip;

  Future<void> _describeNewItem(BuildContext context) async {
    final created = await Navigator.of(context).push<Good>(
      MaterialPageRoute(
        builder: (_) => GoodFormScreen(
          initialFromCity: trip.fromCity,
          initialToCity: trip.toCity,
          submitLabel: 'Continue',
        ),
      ),
    );

    // Newly created: close the sheet so the caller sends the request.
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
              'What are you sending on this trip?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              "You can describe it now — no need to have posted it beforehand.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            if (goods.isNotEmpty) ...[
              Text(
                'Your existing items',
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
                  itemCount: goods.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final good = goods[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${good.fromCity} → ${good.toCity}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        good.itemDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text('${good.weightKg.toStringAsFixed(1)} kg'),
                      onTap: () => Navigator.of(context).pop(good),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
            ],
            OutlinedButton.icon(
              onPressed: () => _describeNewItem(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Describe a new item to send'),
            ),
          ],
        ),
      ),
    );
  }
}
