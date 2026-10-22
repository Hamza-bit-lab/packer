import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/feed_repository.dart';
import '../../../core/models/good.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/skeleton.dart';
import '../../auth/providers/auth_provider.dart';
import '../../goods/screens/good_detail_screen.dart';
import '../widgets/good_card.dart';

/// Browse all items with no search gate; mirrors [AllTravelersScreen].
class AllItemsScreen extends StatefulWidget {
  const AllItemsScreen({super.key});

  @override
  State<AllItemsScreen> createState() => _AllItemsScreenState();
}

class _AllItemsScreenState extends State<AllItemsScreen> {
  late final FeedRepository _repository;
  final List<Good> _goods = [];
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
      final result = await _repository.fetchGoods(page: _page);
      if (!mounted) return;
      setState(() {
        if (reset) _goods.clear();
        _goods.addAll(result.items);
        _hasMore = result.hasMore;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Could not load items. Pull down to try again.',
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
      appBar: AppBar(title: const Text('Featured Items')),
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

    if (_errorMessage != null && _goods.isEmpty) {
      return _MessageView(message: _errorMessage!, onRetry: _load);
    }

    if (_goods.isEmpty) {
      return _MessageView(message: 'No items found yet.');
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _goods.length + 1,
        itemBuilder: (context, index) {
          if (index == _goods.length) {
            return _buildFooter();
          }

          final good = _goods[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GoodCard(
              good: good,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => GoodDetailScreen(good: good)),
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
