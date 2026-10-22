import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/bookings/screens/booking_detail_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/feedback/screens/feature_requests_screen.dart';
import '../../features/goods/screens/good_detail_screen.dart';
import '../../features/profile/screens/id_verification_screen.dart';
import '../../features/trips/screens/trip_detail_screen.dart';
import '../api/api_client.dart';
import '../api/device_token_repository.dart';
import '../api/good_repository.dart';
import '../api/profile_repository.dart';
import '../api/trip_repository.dart';

/// Used by [MaterialApp.navigatorKey]; lets push taps navigate on cold start.
final navigatorKey = GlobalKey<NavigatorState>();

/// Must match the channel created on launch and the backend's channel_id.
const _androidChannelId = 'packer_notifications';

/// Must be top-level; runs in a separate isolate for background pushes.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {}

/// Registers this device for push and keeps its token synced with the backend.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  String? _lastRegisteredToken;
  StreamSubscription<String>? _tokenRefreshSub;

  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _foregroundMessages = StreamController<RemoteMessage>.broadcast();

  /// Fires for pushes received while the app is in the foreground.
  Stream<RemoteMessage> get foregroundMessages => _foregroundMessages.stream;

  /// Shows pushes while the app is open; call once at startup.
  Future<void> listenForForegroundMessages() async {
    try {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      if (Platform.isAndroid) {
        await _localNotifications.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          ),
          onDidReceiveNotificationResponse: (response) {
            _navigateFromPayload(response.payload);
          },
        );

        // Picks up a local-notification tap that launched the app.
        final launch = await _localNotifications
            .getNotificationAppLaunchDetails();
        if (launch?.didNotificationLaunchApp ?? false) {
          _navigateFromPayload(launch!.notificationResponse?.payload);
        }
      }

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    } catch (e) {
      debugPrint('Could not set up foreground notifications: $e');
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    _foregroundMessages.add(message);

    // iOS already shows its own banner (see the presentation options above).
    if (!Platform.isAndroid) return;

    final title = message.notification?.title;
    final body = message.notification?.body;
    if (title == null && body == null) return;

    try {
      // Reusing the tag as id collapses repeated pushes into one notification.
      final key =
          message.notification?.android?.tag ??
          message.messageId ??
          DateTime.now().microsecondsSinceEpoch.toString();

      await _localNotifications.show(
        id: key.hashCode & 0x7fffffff,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            'Packer notifications',
            channelDescription:
                'Messages, booking updates, and other Packer alerts.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      debugPrint('Could not show foreground notification: $e');
    }
  }

  void _navigateFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      _navigateFromData(
        Map<String, dynamic>.from(jsonDecode(payload) as Map),
      );
    } catch (e) {
      debugPrint('Could not read notification payload: $e');
    }
  }

  /// Creates the high-importance Android channel; no-op on iOS.
  Future<void> createAndroidNotificationChannel() async {
    if (!Platform.isAndroid) return;

    try {
      const channel = AndroidNotificationChannel(
        _androidChannelId,
        'Packer notifications',
        description: 'Messages, booking updates, and other Packer alerts.',
        importance: Importance.high,
      );

      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('Could not create Android notification channel: $e');
    }
  }

  /// Handles taps on pushes from background/terminated; call after `runApp`.
  void listenForNotificationTaps() {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleTap(message);
    });
  }

  Future<void> _handleTap(RemoteMessage message) =>
      _navigateFromData(message.data);

  Future<void> _navigateFromData(Map<String, dynamic> data) async {
    if (!await _waitForNavigator()) return;

    try {
      final bookingId = int.tryParse(data['booking_id'] ?? '');
      if (bookingId != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => BookingDetailScreen(bookingId: bookingId),
          ),
        );
        return;
      }

      final client = navigatorKey.currentContext!.read<AuthProvider>().client;

      final tripId = int.tryParse(data['trip_id'] ?? '');
      if (tripId != null) {
        final trip = await TripRepository(client).fetchOne(tripId);
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
        );
        return;
      }

      final goodId = int.tryParse(data['good_id'] ?? '');
      if (goodId != null) {
        final good = await GoodRepository(client).fetchOne(goodId);
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => GoodDetailScreen(good: good)),
        );
        return;
      }

      final senderId = int.tryParse(data['sender_id'] ?? '');
      if (data['type'] == 'new_message' && senderId != null) {
        final otherParty = await ProfileRepository(
          client,
        ).fetchPublicProfile(senderId);
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => ChatScreen(otherParty: otherParty)),
        );
        return;
      }

      if (data['type'] == 'feature_request_status' ||
          data['type'] == 'feature_request_votes') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const FeatureRequestsScreen()),
        );
        return;
      }

      // An ID verification review has a fixed destination, no id needed.
      if (data['type'] == 'id_verification_reviewed') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const IdVerificationScreen()),
        );
      }
    } catch (e) {
      debugPrint('Could not navigate from notification tap: $e');
    }
  }

  /// Polls briefly for the navigator on cold start instead of dropping the tap.
  Future<bool> _waitForNavigator() async {
    for (var attempt = 0; attempt < 50; attempt++) {
      if (navigatorKey.currentState != null) return true;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return false;
  }

  Future<void> registerForCurrentUser(ApiClient client) async {
    // Best-effort: must never throw into the caller.
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await messaging.getToken();
      if (token == null) return;

      await _send(client, token);
      _lastRegisteredToken = token;

      // Keeps the backend token current when FCM rotates it. Replace any
      // listener left from an earlier login so they don't stack up.
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
        newToken,
      ) {
        _send(client, newToken);
        _lastRegisteredToken = newToken;
      });
    } catch (e) {
      debugPrint('Could not register for push notifications: $e');
    }
  }

  Future<void> unregisterForCurrentUser(ApiClient client) async {
    // Best-effort: must never throw, logout has to succeed.
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    try {
      final token =
          _lastRegisteredToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await DeviceTokenRepository(client).unregister(token);
      }
    } catch (e) {
      debugPrint('Could not unregister device token: $e');
    }
    _lastRegisteredToken = null;
  }

  Future<void> _send(ApiClient client, String token) async {
    try {
      await DeviceTokenRepository(
        client,
      ).register(token: token, platform: Platform.isIOS ? 'ios' : 'android');
    } catch (e) {
      debugPrint('Could not register device token: $e');
    }
  }
}
