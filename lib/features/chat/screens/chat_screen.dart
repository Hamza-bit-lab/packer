import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/message_repository.dart';
import '../../../core/api/profile_repository.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/user.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feed/widgets/date_format.dart';
import '../../feed/widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.otherParty});

  final User otherParty;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 4);

  // "Online"/"Last seen" only needs a refresh every few polls.
  static const _presenceEveryPolls = 5;

  late final MessageRepository _repository;
  late final ProfileRepository _profileRepository;
  final _bodyController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isPolling = false;
  int _pollCount = 0;

  // Bumped when a send completes, so a poll that started before it is dropped.
  int _sendEpoch = 0;

  /// Refreshed with the message poll; starts from the caller's copy.
  late User _otherParty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _otherParty = widget.otherParty;
    final client = context.read<AuthProvider>().client;
    _repository = MessageRepository(client);
    _profileRepository = ProfileRepository(client);
    _load();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _bodyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // No polling while the app is in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(silently: true);
      _startPolling();
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _load(silently: true));
  }

  Future<void> _load({bool silently = false}) async {
    if (_isPolling) return;
    _isPolling = true;
    if (!silently) setState(() => _isLoading = true);

    final epoch = _sendEpoch;
    try {
      final messages = await _repository.fetchForUser(widget.otherParty.id);
      if (!mounted || epoch != _sendEpoch) return;

      if (!silently || _hasChanged(messages)) {
        final stickToBottom = _isNearBottom();
        setState(() => _messages = messages);
        if (!silently) {
          _scrollToBottom(jump: true);
        } else if (stickToBottom) {
          _scrollToBottom();
        }
      }
    } catch (_) {
      // Ignore transient poll errors.
    } finally {
      _isPolling = false;
      if (mounted && !silently) setState(() => _isLoading = false);
    }

    if (mounted && _pollCount++ % _presenceEveryPolls == 0) {
      _refreshPresence();
    }
  }

  bool _hasChanged(List<ChatMessage> fresh) {
    if (fresh.length != _messages.length) return true;
    return fresh.isNotEmpty && fresh.last.id != _messages.last.id;
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels < 150;
  }

  Future<void> _refreshPresence() async {
    try {
      final fresh = await _profileRepository.fetchPublicProfile(
        widget.otherParty.id,
      );
      if (mounted) setState(() => _otherParty = fresh);
    } catch (_) {
      // Presence is optional; keep the last known value on failure.
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final end = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(end);
      } else {
        _scrollController.animateTo(
          end,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _bodyController.clear();

    try {
      final message = await _repository.send(widget.otherParty.id, body);
      if (!mounted) return;
      _sendEpoch++;
      setState(() => _messages = [..._messages, message]);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      // Put the text back so a failed send can be retried.
      if (_bodyController.text.isEmpty) {
        _bodyController.value = TextEditingValue(
          text: body,
          selection: TextSelection.collapsed(offset: body.length),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(user: _otherParty, size: 32),
                if (_otherParty.isOnline)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_otherParty.name),
                Text(
                  _otherParty.isOnline
                      ? 'Online'
                      : (_otherParty.lastSeenAt != null
                            ? 'Last seen ${formatLastSeen(_otherParty.lastSeenAt!)}'
                            : ''),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: _otherParty.isOnline
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'No messages yet. Say hello!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) =>
          _MessageBubble(message: _messages[index]),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _bodyController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Message',
                  filled: true,
                  fillColor: AppColors.field,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isSending ? null : _send,
              style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              icon: _isSending
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isMine
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final color = message.isMine ? AppColors.ink : AppColors.field;
    final textColor = message.isMine ? Colors.white : AppColors.textPrimary;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(message.isMine ? 16 : 4),
      bottomRight: Radius.circular(message.isMine ? 4 : 16),
    );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(color: color, borderRadius: radius),
        child: Text(
          message.body,
          style: TextStyle(color: textColor, fontSize: 14),
        ),
      ),
    );
  }
}
