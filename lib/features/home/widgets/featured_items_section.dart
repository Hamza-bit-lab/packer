import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/feed_repository.dart';
import '../../../core/models/good.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/featured_hero_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/screens/all_items_screen.dart';
import '../../feed/widgets/user_avatar.dart';
import '../../goods/screens/good_detail_screen.dart';

const _maxFeaturedCards = 5;

/// Home's Featured Items carousel; mirrors [FeaturedTravelersSection].
class FeaturedItemsSection extends StatefulWidget {
  const FeaturedItemsSection({super.key});

  @override
  State<FeaturedItemsSection> createState() => _FeaturedItemsSectionState();
}

class _FeaturedItemsSectionState extends State<FeaturedItemsSection> {
  List<Good>? _goods;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repository = FeedRepository(context.read<AuthProvider>().client);
      final result = await repository.fetchGoods(page: 1);
      if (mounted) {
        setState(() => _goods = result.items.take(_maxFeaturedCards).toList());
      }
    } catch (_) {
      if (mounted) {
        setState(() => _goods = []);
      }
    }
  }

  void _openAll() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AllItemsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (_goods != null && _goods!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Featured Items',
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
          child: _goods == null
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _goods!.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == _goods!.length) {
                      return FeaturedViewAllCard(onTap: _openAll);
                    }
                    final good = _goods![index];
                    return FeaturedHeroCard(
                      avatar: UserAvatar(user: good.sender, size: 64),
                      title: good.sender.name,
                      fromLabel: good.fromCity,
                      toLabel: good.toCity,
                      chipLabel:
                          '${good.offeredReward.toStringAsFixed(0)} ${good.currencyType}',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GoodDetailScreen(good: good),
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
