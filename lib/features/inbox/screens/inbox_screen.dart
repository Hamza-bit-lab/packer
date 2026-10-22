import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/message_repository.dart';
import '../../../core/models/conversation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeleton.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/screens/chat_screen.dart';
import '../../feed/widgets/user_avatar.dart';
import '../providers/inbox_provider.dart';

/// List of the user's conversations; tap to open the chat.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Conversation> _conversations = [];
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
      final repository = MessageRepository(context.read<AuthProvider>().client);
      _conversations = await repository.fetchConversations();
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Could not load your messages. Pull down to try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openChat(Conversation conversation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(otherParty: conversation.otherUser),
      ),
    );
    if (!mounted) return;
    context.read<InboxProvider>().refreshNow();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: SectionHeader(title: 'Messages'),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SkeletonListTiles(count: 7),
      );
    }

    if (_errorMessage != null && _conversations.isEmpty) {
      return _MessageView(message: _errorMessage!, onRetry: _load);
    }

    if (_conversations.isEmpty) {
      return _MessageView(
        message:
            "No messages yet. Start a conversation from any trip or item's details page.",
        onRetry: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
        itemCount: _conversations.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 78),
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          final hasUnread = conversation.unreadCount > 0;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 6,
            ),
            leading: UserAvatar(user: conversation.otherUser, size: 48),
            title: Text(
              conversation.otherUser.name,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              (conversation.lastMessage.isMine ? 'You: ' : '') +
                  conversation.lastMessage.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasUnread
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13.5,
              ),
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTimestamp(conversation.lastMessage.createdAt),
                  style: TextStyle(
                    color: hasUnread
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            onTap: () => _openChat(conversation),
          );
        },
      ),
    );
  }

  static String _formatTimestamp(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;

    if (isToday) {
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final minute = local.minute.toString().padLeft(2, '0');
      return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day) {
      return 'Yesterday';
    }

    return '${local.month}/${local.day}/${local.year}';
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
              Icons.chat_bubble_outline_rounded,
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
