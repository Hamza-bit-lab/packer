import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/providers/preferences_provider.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/verify_email_screen.dart';
import 'features/shell/screens/main_shell.dart';
import 'features/shell/screens/splash_screen.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init runs after the first frame so it doesn't block the splash.
  runApp(const PackerApp());
  unawaited(_initializeFirebase());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
    // Android drops pushes if the channel isn't registered first.
    await PushNotificationService.instance.createAndroidNotificationChannel();
    PushNotificationService.instance.listenForNotificationTaps();
    await PushNotificationService.instance.listenForForegroundMessages();
  } catch (e) {
    // Push is optional; the app works even if Firebase init fails.
    debugPrint(
      'Firebase init failed, push notifications will be unavailable: $e',
    );
  }
}

class PackerApp extends StatelessWidget {
  const PackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => PreferencesProvider()),
      ],
      child: MaterialApp(
        title: 'Packer',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: AppTheme.light(),
        // Light theme only, regardless of the device setting.
        themeMode: ThemeMode.light,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  int? _skippedVerificationForUserId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.id;

    // Forget the skip on logout so the next sign-in sees the screen again.
    if (auth.status == AuthStatus.unauthenticated) {
      _skippedVerificationForUserId = null;
    }

    if (auth.status == AuthStatus.authenticated &&
        auth.user?.emailVerified == false &&
        _skippedVerificationForUserId != userId) {
      return VerifyEmailScreen(
        onSkip: () => setState(() => _skippedVerificationForUserId = userId),
      );
    }

    return switch (auth.status) {
      AuthStatus.checking => const SplashScreen(),
      AuthStatus.authenticated => const MainShell(),
      AuthStatus.unauthenticated => const LoginScreen(),
    };
  }
}
