import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/feed_repository.dart';
import '../../../core/models/good.dart';
import '../../../core/models/trip.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/segmented_pill_toggle.dart';
import '../../auth/providers/auth_provider.dart';
import '../../goods/screens/good_detail_screen.dart';
import '../../trips/screens/trip_detail_screen.dart';
import '../widgets/city_search_bar.dart';
import '../widgets/good_card.dart';
import '../widgets/trip_card.dart';

enum FeedType { travelers, goods }

/// Simple search screen: From/To fields with results below.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.type});

  final FeedType type;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late int _selectedIndex = widget.type == FeedType.travelers ? 0 : 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: SegmentedPillToggle(
                      labels: const ['Travelers', 'Items'],
                      selectedIndex: _selectedIndex,
                      onChanged: (index) =>
                          setState(() => _selectedIndex = index),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: const [
                  _FeedList(isTravelers: true),
                  _FeedList(isTravelers: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedList extends StatefulWidget {
  const _FeedList({required this.isTravelers});

  final bool isTravelers;

  @override
  State<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends State<_FeedList>
    with AutomaticKeepAliveClientMixin {
  late final FeedRepository _repository;
  String _fromCity = '';
  String _toCity = '';

  final List<Trip> _trips = [];
  final List<Good> _goods = [];

  bool _hasSearched = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _errorMessage;
  int _page = 1;
  final FeedFilters _filters = const FeedFilters();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _repository = FeedRepository(context.read<AuthProvider>().client);
  }

  Future<void> _search() async {
    _hasSearched = true;
    await _load();
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
      if (widget.isTravelers) {
        final result = await _repository.fetchTrips(
          fromCity: _fromCity,
          toCity: _toCity,
          page: _page,
          filters: _filters,
        );
        if (!mounted) return;
        setState(() {
          if (reset) _trips.clear();
          _trips.addAll(result.items);
          _hasMore = result.hasMore;
        });
      } else {
        final result = await _repository.fetchGoods(
          fromCity: _fromCity,
          toCity: _toCity,
          page: _page,
          filters: _filters,
        );
        if (!mounted) return;
        setState(() {
          if (reset) _goods.clear();
          _goods.addAll(result.items);
          _hasMore = result.hasMore;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(
        () =>
            _errorMessage = 'Could not load listings. Pull down to try again.',
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
    super.build(context);
    final itemCount = widget.isTravelers ? _trips.length : _goods.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: CitySearchBar(
            initialFromCity: _fromCity,
            initialToCity: _toCity,
            onFromChanged: (value) => _fromCity = value,
            onToChanged: (value) => _toCity = value,
            onSearch: _search,
          ),
        ),
        Expanded(child: _buildBody(itemCount)),
      ],
    );
  }

  Widget _buildBody(int itemCount) {
    if (!_hasSearched) {
      return _MessageView(
        icon: Icons.search_rounded,
        message: 'Enter a from and to city above, then search.',
      );
    }

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage != null && itemCount == 0) {
      return _MessageView(message: _errorMessage!, onRetry: _load);
    }

    if (itemCount == 0) {
      return _MessageView(
        message: widget.isTravelers
            ? 'No trips found for these cities yet.'
            : 'No items found for these cities yet.',
        onRetry: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: itemCount + 1,
        itemBuilder: (context, index) {
          if (index == itemCount) {
            return _buildFooter();
          }

          if (widget.isTravelers) {
            final trip = _trips[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TripCard(
                trip: trip,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TripDetailScreen(trip: trip),
                  ),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GoodCard(
              good: _goods[index],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GoodDetailScreen(good: _goods[index]),
                ),
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
  const _MessageView({
    required this.message,
    this.onRetry,
    this.icon = Icons.travel_explore_rounded,
  });

  final String message;
  final Future<void> Function()? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 48),
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
