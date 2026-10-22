import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/notification_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

/// Notification on/off toggles per category; each change saves immediately.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  // Toggle currently saving, so only that row shows a spinner.
  String? _savingKey;
  String? _errorMessage;

  Future<void> _toggle(String key, Future<void> Function() persist) async {
    setState(() {
      _savingKey = key;
      _errorMessage = null;
    });

    try {
      await persist();
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errorMessage = e.toString().replaceFirst('ApiException: ', ''),
      );
    } finally {
      if (mounted) setState(() => _savingKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) return const SizedBox.shrink();

    Future<void> update({
      bool? bookings,
      bool? messages,
      bool? routeAlerts,
    }) async {
      final repository = NotificationRepository(auth.client);
      final updated = await repository.updatePreferences(
        notifyBookings: bookings,
        notifyMessages: messages,
        notifyRouteAlerts: routeAlerts,
      );
      auth.setUser(updated);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose which activity sends you an in-app and push notification.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: AppColors.error, fontSize: 12.5),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Material(
                  color: AppColors.surface,
                  child: Column(
                    children: [
                      _PreferenceRow(
                        icon: Icons.local_shipping_outlined,
                        title: 'Bookings',
                        subtitle:
                            'Requests, status updates, and ratings on your shipments',
                        value: user.notifyBookings,
                        isSaving: _savingKey == 'bookings',
                        onChanged: (value) =>
                            _toggle('bookings', () => update(bookings: value)),
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: AppColors.border,
                      ),
                      _PreferenceRow(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Messages',
                        subtitle:
                            'New chat messages from travelers and senders',
                        value: user.notifyMessages,
                        isSaving: _savingKey == 'messages',
                        onChanged: (value) =>
                            _toggle('messages', () => update(messages: value)),
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: AppColors.border,
                      ),
                      _PreferenceRow(
                        icon: Icons.bookmark_border_rounded,
                        title: 'Route Alerts',
                        subtitle:
                            'New trips or items matching your saved routes',
                        value: user.notifyRouteAlerts,
                        isSaving: _savingKey == 'route_alerts',
                        onChanged: (value) => _toggle(
                          'route_alerts',
                          () => update(routeAlerts: value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isSaving,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool isSaving;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isSaving)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          else
            Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
