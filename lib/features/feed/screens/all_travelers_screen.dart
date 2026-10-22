import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/feed_repository.dart';
import '../../../core/models/trip.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton.dart';
import '../../auth/providers/auth_provider.dart';
import '../../trips/screens/trip_detail_screen.dart';
import '../widgets/trip_card.dart';

/// Browse all travelers with no search gate.
class AllTravelersScreen extends StatefulWidget {
  const AllTravelersScreen({super.key});

  @override
  State<AllTravelersScreen> createState() => _AllTravelersScreenState();
}

class _AllTravelersScreenState extends State<AllTravelersScreen> {
  late final FeedRepository _repository;
  final List<Trip> _trips = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _errorMessage;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _repository = FeedRepository(context.read<AuthProvider>().client);
    _load();
  }

  Future<void> _load({bool reset = true}) async {
    setState(() {
      if (reset) {
        _isLoading = true;
        _page = 1;
      } else {
        _isLoadingMore = true;
      }
      _errorMessage = null;
    });

    try {
      final result = await _repository.fetchTrips(page: _page);
      if (!mounted) return;
      setState(() {
        if (reset) _trips.clear();
        _trips.addAll(result.items);
        _hasMore = result.hasMore;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () =>
            _errorMessage = 'Could not load travelers. Pull down to try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _page += 1;
    await _load(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Featured Travelers')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SkeletonCards(count: 4, cardHeight: 200),
      );
    }

    if (_errorMessage != null && _trips.isEmpty) {
      return _MessageView(message: _errorMessage!, onRetry: _load);
    }

    if (_trips.isEmpty) {
      return _MessageView(message: 'No travelers found yet.');
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _trips.length + 1,
        itemBuilder: (context, index) {
          if (index == _trips.length) {
            return _buildFooter();
          }

          final trip = _trips[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: TripCard(
              trip: trip,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    if (_isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_hasMore) {
      return Center(
        child: TextButton(onPressed: _loadMore, child: const Text('Load more')),
      );
    }

    return const SizedBox(height: 8);
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.travel_explore_rounded,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
