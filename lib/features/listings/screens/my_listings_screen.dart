import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/good_repository.dart';
import '../../../core/api/trip_repository.dart';
import '../../../core/models/good.dart';
import '../../../core/models/trip.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/segmented_pill_toggle.dart';
import '../../../core/widgets/skeleton.dart';
import '../../auth/providers/auth_provider.dart';
import '../../goods/screens/good_detail_screen.dart';
import '../../goods/screens/good_form_screen.dart';
import '../../trips/screens/trip_detail_screen.dart';
import '../../trips/screens/trip_form_screen.dart';
import '../widgets/my_good_card.dart';
import '../widgets/my_trip_card.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  bool _showingTrips = true;
  List<Trip> _trips = [];
  List<Good> _goods = [];
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

    final auth = context.read<AuthProvider>();
    final userId = auth.user!.id;

    try {
      if (_showingTrips) {
        _trips = await TripRepository(auth.client).fetchMine(userId);
      } else {
        _goods = await GoodRepository(auth.client).fetchMine(userId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Could not load your listings. Pull down to try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createNew() async {
    if (_showingTrips) {
      final saved = await Navigator.of(
        context,
      ).push<Trip>(MaterialPageRoute(builder: (_) => const TripFormScreen()));
      if (saved != null) _load();
    } else {
      final saved = await Navigator.of(
        context,
      ).push<Good>(MaterialPageRoute(builder: (_) => const GoodFormScreen()));
      if (saved != null) _load();
    }
  }

  Future<void> _editTrip(Trip trip) async {
    final saved = await Navigator.of(
      context,
    ).push<Trip>(MaterialPageRoute(builder: (_) => TripFormScreen(trip: trip)));
    if (saved != null) _load();
  }

  Future<void> _editGood(Good good) async {
    final saved = await Navigator.of(
      context,
    ).push<Good>(MaterialPageRoute(builder: (_) => GoodFormScreen(good: good)));
    if (saved != null) _load();
  }

  Future<void> _deleteTrip(Trip trip) async {
    final confirmed = await _confirmDelete('trip');
    if (confirmed != true || !mounted) return;

    try {
      await TripRepository(context.read<AuthProvider>().client).delete(trip.id);
      _load();
    } catch (_) {
      if (mounted) _showError('Could not delete this trip.');
    }
  }

  Future<void> _deleteGood(Good good) async {
    final confirmed = await _confirmDelete('item');
    if (confirmed != true || !mounted) return;

    try {
      await GoodRepository(context.read<AuthProvider>().client).delete(good.id);
      _load();
    } catch (_) {
      if (mounted) _showError('Could not delete this item.');
    }
  }

  Future<bool?> _confirmDelete(String noun) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete this $noun?'),
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
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = _showingTrips ? _trips.length : _goods.length;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _createNew,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add_rounded, color: AppColors.onPrimary),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionHeader(
                    title: 'My Posts',
                    subtitle: _showingTrips
                        ? "Routes you're traveling with spare luggage space"
                        : 'Things you want someone to carry for you',
                  ),
                  const SizedBox(height: 16),
                  SegmentedPillToggle(
                    labels: const ['My Trips', 'My Items'],
                    selectedIndex: _showingTrips ? 0 : 1,
                    onChanged: (index) {
                      setState(() => _showingTrips = index == 0);
                      _load();
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(itemCount)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(int itemCount) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: SkeletonCards(count: 3, cardHeight: 210),
      );
    }

    if (_errorMessage != null && itemCount == 0) {
      return _MessageView(message: _errorMessage!, onRetry: _load);
    }

    if (itemCount == 0) {
      return _MessageView(
        message: _showingTrips
            ? "You haven't posted any trips yet. Tap + to add one."
            : "You haven't posted any items yet. Tap + to add one.",
        onRetry: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
        itemCount: itemCount + 1,
        itemBuilder: (context, index) {
          if (index == itemCount) {
            return _AddAnotherTip(
              showingTrips: _showingTrips,
              onTap: _createNew,
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _showingTrips
                ? MyTripCard(
                    trip: _trips[index],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TripDetailScreen(trip: _trips[index]),
                      ),
                    ),
                    onEdit: () => _editTrip(_trips[index]),
                    onDelete: () => _deleteTrip(_trips[index]),
                  )
                : MyGoodCard(
                    good: _goods[index],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GoodDetailScreen(good: _goods[index]),
                      ),
                    ),
                    onEdit: () => _editGood(_goods[index]),
                    onDelete: () => _deleteGood(_goods[index]),
                  ),
          );
        },
      ),
    );
  }
}

/// Trailing nudge shown after the last card — fills the empty space below a
/// short list instead of leaving it blank, and points at the FAB.
class _AddAnotherTip extends StatelessWidget {
  const _AddAnotherTip({required this.showingTrips, required this.onTap});

  final bool showingTrips;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x0AFF5A46),
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
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  showingTrips
                      ? 'Got another trip? Post it to reach more senders.'
                      : 'Got another item to send? Post it here.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
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
              Icons.inventory_2_outlined,
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
