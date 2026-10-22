import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/feed_repository.dart';
import '../../../core/models/trip.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/featured_hero_card.dart';
import '../../../core/widgets/skeleton.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/screens/all_travelers_screen.dart';
import '../../feed/widgets/user_avatar.dart';
import '../../trips/screens/trip_detail_screen.dart';

const _maxFeaturedCards = 5;

/// Home's Featured Travelers carousel, capped at [_maxFeaturedCards].
class FeaturedTravelersSection extends StatefulWidget {
  const FeaturedTravelersSection({super.key});

  @override
  State<FeaturedTravelersSection> createState() =>
      _FeaturedTravelersSectionState();
}

class _FeaturedTravelersSectionState extends State<FeaturedTravelersSection> {
  List<Trip>? _trips;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthProvider>();
      final repository = FeedRepository(auth.client);
      final result = await repository.fetchTrips(page: 1);
      final myId = auth.user?.id;
      if (mounted) {
        setState(
          () => _trips = result.items
              .where((trip) => trip.traveler.id != myId)
              .take(_maxFeaturedCards)
              .toList(),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _trips = []);
      }
    }
  }

  void _openAll() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AllTravelersScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (_trips != null && _trips!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Featured Travelers',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ),
            TextButton(
              onPressed: _openAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View all',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: featuredCardHeight,
          child: _trips == null
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => const SkeletonCard(
                    width: 172,
                    height: featuredCardHeight,
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _trips!.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == _trips!.length) {
                      return FeaturedViewAllCard(onTap: _openAll, whiteBackground: true);
                    }
                    final trip = _trips![index];
                    return FeaturedHeroCard(
                      avatar: UserAvatar(user: trip.traveler, size: 64),
                      title: trip.traveler.name,
                      fromLabel: trip.fromCity,
                      toLabel: trip.toCity,
                      chipLabel:
                          '${trip.ratePerKg.toStringAsFixed(0)} ${trip.currencyType}',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TripDetailScreen(trip: trip),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
