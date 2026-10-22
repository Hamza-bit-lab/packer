import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/feature_request_repository.dart';
import '../../../core/models/feature_request.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/widgets/date_format.dart';
import '../widgets/suggest_feature_sheet.dart';

class FeatureRequestsScreen extends StatefulWidget {
  const FeatureRequestsScreen({super.key});

  @override
  State<FeatureRequestsScreen> createState() => _FeatureRequestsScreenState();
}

class _FeatureRequestsScreenState extends State<FeatureRequestsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<FeatureRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Request being voted on, so only its buttons disable.
  int? _votingId;

  FeatureRequestRepository get _repository =>
      FeatureRequestRepository(context.read<AuthProvider>().client);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await _repository.fetchAll(
        search: _searchController.text,
      );
      if (mounted) setState(() => _requests = requests);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Could not load feature requests. Pull down to try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _suggestFeature() async {
    final result = await showModalBottomSheet<SuggestedFeature>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      builder: (_) => const SuggestFeatureSheet(),
    );
    if (result == null) return;

    try {
      final created = await _repository.create(
        title: result.title,
        description: result.description,
      );
      if (!mounted) return;
      setState(() => _requests = [created, ..._requests]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Thanks — your suggestion has been submitted.'),
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

  Future<void> _vote(FeatureRequest request, VoteDirection direction) async {
    setState(() => _votingId = request.id);

    try {
      final updated = await _repository.vote(request.id, direction);
      if (!mounted) return;
      setState(
        () => _requests = _requests
            .map((r) => r.id == updated.id ? updated : r)
            .toList(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _votingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feature Requests')),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by title or description...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: AppColors.onPrimary,
                    size: 34,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'What should we build next?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Suggest features you'd like to see!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.onPrimary.withValues(alpha: 0.7),
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _buildList(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 10, 18, 14),
        child: ElevatedButton.icon(
          onPressed: _suggestFeature,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Suggest a Feature'),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null && _requests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            _searchController.text.isEmpty
                ? 'No suggestions yet — be the first!'
                : 'No matches for your search.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
          ),
        ),
      );
    }

    return Column(
      children: _requests
          .map(
            (request) => _FeatureRequestCard(
              request: request,
              isVoting: _votingId == request.id,
              onVote: (direction) => _vote(request, direction),
            ),
          )
          .toList(),
    );
  }
}

class _FeatureRequestCard extends StatelessWidget {
  const _FeatureRequestCard({
    required this.request,
    required this.isVoting,
    required this.onVote,
  });

  final FeatureRequest request;
  final bool isVoting;
  final ValueChanged<VoteDirection> onVote;

  static Map<FeatureRequestStatus, (String, Color)> get _statusMeta => {
    FeatureRequestStatus.open: ('Open', AppColors.info),
    FeatureRequestStatus.inProgress: ('In Progress', AppColors.warning),
    FeatureRequestStatus.completed: ('Completed', AppColors.success),
  };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _statusMeta[request.status]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  request.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lightbulb_rounded, size: 13, color: color),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _VoteButton(
                icon: Icons.arrow_upward_rounded,
                count: request.upvotes,
                active: request.myVote == VoteDirection.up,
                enabled: !isVoting,
                onTap: () => onVote(VoteDirection.up),
              ),
              const SizedBox(width: 8),
              _VoteButton(
                icon: Icons.arrow_downward_rounded,
                count: request.downvotes,
                active: request.myVote == VoteDirection.down,
                enabled: !isVoting,
                onTap: () => onVote(VoteDirection.down),
              ),
              const Spacer(),
              if (request.submittedBy != null) ...[
                Text(
                  request.isMine ? 'You' : request.submittedBy!,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 3),
              Text(
                formatShortDate(request.createdAt),
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.icon,
    required this.count,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primarySoft : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadii.button),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadii.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  color: active ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
