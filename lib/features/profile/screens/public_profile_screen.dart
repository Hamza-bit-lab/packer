import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/block_repository.dart';
import '../../../core/api/profile_repository.dart';
import '../../../core/api/report_repository.dart';
import '../../../core/models/rating.dart';
import '../../../core/models/user.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/stat_box.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/widgets/id_verified_badge.dart';
import '../../feed/widgets/user_avatar.dart';
import '../../feed/widgets/verified_badge.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final int userId;

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  User? _user;
  List<Rating> _ratings = [];
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

    try {
      final repository = ProfileRepository(context.read<AuthProvider>().client);
      final results = await Future.wait([
        repository.fetchPublicProfile(widget.userId),
        repository.fetchRatings(widget.userId),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as User;
        _ratings = results[1] as List<Rating>;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Could not load this profile. Pull down to try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _report() async {
    final result = await showDialog<_ReportSubmission>(
      context: context,
      builder: (context) => const _ReportDialog(),
    );
    if (result == null || !mounted) return;

    try {
      await ReportRepository(context.read<AuthProvider>().client).reportUser(
        widget.userId,
        reason: result.reason,
        details: result.details,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Thanks — your report has been submitted for review.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _block() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${_user?.name ?? 'this user'}?'),
        content: const Text(
          "You won't see each other's listings anymore, and neither of you can message the other.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await BlockRepository(
        context.read<AuthProvider>().client,
      ).block(widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_user?.name ?? 'User'} has been blocked.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile =
        context.watch<AuthProvider>().user?.id == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!isOwnProfile && _user != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'report') _report();
                if (value == 'block') _block();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'report', child: Text('Report user')),
                PopupMenuItem(value: 'block', child: Text('Block user')),
              ],
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final user = _user;
    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage ?? 'Profile not found.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                UserAvatar(user: user, size: 88),
                const SizedBox(height: 14),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    if (user.emailVerified) ...[
                      const SizedBox(width: 6),
                      const VerifiedBadge(size: 17),
                    ],
                    if (user.isIdVerified) ...[
                      const SizedBox(width: 6),
                      const IdVerifiedBadge(size: 17),
                    ],
                  ],
                ),
                if (user.country != null || user.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (user.country != null) user.country!,
                      if (user.createdAt != null)
                        'Since ${_formatMemberSince(user.createdAt!)}',
                    ].join(' · '),
                    style: TextStyle(
                      color: AppColors.onPrimary.withValues(alpha: 0.7),
                      fontSize: 12.5,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatBox(
                          label: 'Rating',
                          value: '${user.averageRating.toStringAsFixed(1)} ★',
                          tint: AppColors.onPrimary.withValues(alpha: 0.12),
                          onTint: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatBox(
                          label: 'Reviews',
                          value: '${user.totalReviews}',
                          tint: AppColors.onPrimary.withValues(alpha: 0.12),
                          onTint: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatBox(
                          label: 'Delivered',
                          value: '${user.completedDeliveriesCount}',
                          tint: AppColors.onPrimary.withValues(alpha: 0.12),
                          onTint: AppColors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Reviews',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (_ratings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No reviews yet.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                ),
              ),
            )
          else
            ..._ratings.map((rating) => _RatingTile(rating: rating)),
        ],
      ),
    );
  }

  static String _formatMemberSince(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = date.toLocal();
    return '${months[local.month - 1]} ${local.year}';
  }
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({required this.rating});

  final Rating rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(user: rating.rater, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rating.rater.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating.stars
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (rating.comment != null && rating.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.comment!,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportSubmission {
  _ReportSubmission({required this.reason, required this.details});

  final String reason;
  final String? details;
}

const _reportReasons = {
  'no_show': 'Never showed up',
  'inappropriate_item': 'Inappropriate item',
  'scam_or_fraud': 'Scam or fraud',
  'unsafe_behavior': 'Unsafe behavior',
  'other': 'Other',
};

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String _reason = _reportReasons.keys.first;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report user'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _reason,
            items: _reportReasons.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (value) => setState(() => _reason = value ?? _reason),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _detailsController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Additional details (optional)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            _ReportSubmission(
              reason: _reason,
              details: _detailsController.text,
            ),
          ),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
