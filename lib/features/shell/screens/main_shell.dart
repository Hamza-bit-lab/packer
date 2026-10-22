import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/push_notification_service.dart';
import '../../../core/widgets/bottom_tab_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/screens/home_screen.dart';
import '../../inbox/providers/inbox_provider.dart';
import '../../inbox/screens/inbox_screen.dart';
import '../../legal/safety_disclaimer.dart';
import '../../listings/screens/my_listings_screen.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';

const _hasSeenSafetyDisclaimerKey = 'has_seen_safety_disclaimer';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  late final NotificationProvider _notificationProvider;
  late final InboxProvider _inboxProvider;
  StreamSubscription<dynamic>? _foregroundPushSubscription;

  // Tabs are built lazily on first select, then cached.
  static const _screenBuilders = <Widget Function()>[
    HomeScreen.new,
    MyListingsScreen.new,
    NotificationsScreen.new,
    InboxScreen.new,
    ProfileScreen.new,
  ];

  final _builtScreens = List<Widget?>.filled(_screenBuilders.length, null);

  Widget _screenAt(int index) =>
      _builtScreens[index] ??= _screenBuilders[index]();

  @override
  void initState() {
    super.initState();
    final client = context.read<AuthProvider>().client;
    _notificationProvider = NotificationProvider(client)..start();
    _inboxProvider = InboxProvider(client)..start();
    // Update badges right away on a foreground push.
    _foregroundPushSubscription = PushNotificationService
        .instance
        .foregroundMessages
        .listen((_) {
          _notificationProvider.refreshNow();
          _inboxProvider.refreshNow();
        });
    _maybeShowSafetyDisclaimer();
  }

  /// Shown once per device; a permanent copy is in Profile → Safety Guidelines.
  Future<void> _maybeShowSafetyDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_hasSeenSafetyDisclaimerKey) ?? false) return;

    await prefs.setBool(_hasSeenSafetyDisclaimerKey, true);
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) SafetyDisclaimerDialog.showOnce(context);
    });
  }

  @override
  void dispose() {
    _foregroundPushSubscription?.cancel();
    _notificationProvider.dispose();
    _inboxProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NotificationProvider>.value(
          value: _notificationProvider,
        ),
        ChangeNotifierProvider<InboxProvider>.value(value: _inboxProvider),
      ],
      // Use `builder`'s context (below MultiProvider), not the outer one.
      builder: (context, child) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final unreadMessages = context.watch<InboxProvider>().unreadCount > 0;
    final unreadNotifications =
        context.watch<NotificationProvider>().unreadCount > 0;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: List.generate(
          _screenBuilders.length,
          (i) => i == _index
              ? _screenAt(i)
              : (_builtScreens[i] ?? const SizedBox.shrink()),
        ),
      ),
      bottomNavigationBar: BottomTabBar(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          setState(() => _index = index);
          if (index == 2) _notificationProvider.refreshNow();
          if (index == 3) _inboxProvider.refreshNow();
        },
        items: [
          const TabBarNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Home',
          ),
          const TabBarNavItem(
            icon: Icons.inventory_2_outlined,
            selectedIcon: Icons.inventory_2_rounded,
            label: 'My Posts',
          ),
          TabBarNavItem(
            icon: Icons.notifications_outlined,
            selectedIcon: Icons.notifications_rounded,
            label: 'Notifications',
            showDot: unreadNotifications,
          ),
          TabBarNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            selectedIcon: Icons.chat_bubble_rounded,
            label: 'Inbox',
            showDot: unreadMessages,
          ),
          const TabBarNavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings_rounded,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
