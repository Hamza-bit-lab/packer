import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/block_repository.dart';
import '../../../core/models/user.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/widgets/user_avatar.dart';

/// The people this user has blocked — lets them see who, and undo it.
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<User> _blocked = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Which user is mid-unblock, so only that row shows a spinner.
  int? _unblockingId;

  BlockRepository get _repository =>
      BlockRepository(context.read<AuthProvider>().client);

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
      _blocked = await _repository.fetchBlocked();
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Could not load blocked users. Pull down to try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unblock(User user) async {
    setState(() => _unblockingId = user.id);
    try {
      await _repository.unblock(user.id);
      if (!mounted) return;
      setState(() {
        _blocked = _blocked.where((u) => u.id != user.id).toList();
        _unblockingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} has been unblocked.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _unblockingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not unblock ${user.name}.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage != null && _blocked.isEmpty) {
      return _MessageView(message: _errorMessage!, onRetry: _load);
    }

    if (_blocked.isEmpty) {
      return _MessageView(
        message: "You haven't blocked anyone. Blocked users will show up here.",
        onRetry: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: _blocked.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final user = _blocked[index];
          final isUnblocking = _unblockingId == user.id;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.tile),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.subtle,
            ),
            child: Row(
              children: [
                UserAvatar(user: user, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: isUnblocking ? null : () => _unblock(user),
                  child: isUnblocking
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Text('Unblock'),
                ),
              ],
            ),
          );
        },
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
            Icon(Icons.block_rounded, color: AppColors.textSecondary, size: 48),
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
