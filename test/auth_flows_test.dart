import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pack_and_carry/features/auth/providers/auth_provider.dart';
import 'package:pack_and_carry/features/auth/screens/forgot_password_screen.dart';
import 'package:pack_and_carry/features/auth/screens/login_screen.dart';
import 'package:pack_and_carry/features/auth/screens/reset_password_screen.dart';
import 'package:pack_and_carry/features/profile/widgets/delete_account_dialog.dart';

Widget _app(Widget home) => ChangeNotifierProvider<AuthProvider>(
  create: (_) => AuthProvider(),
  child: MaterialApp(home: home),
);

void main() {
  testWidgets('Login screen links to the forgot-password flow', (tester) async {
    await tester.pumpWidget(_app(const LoginScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(find.text('Send Code'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Forgot-password screen validates the email before sending', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const ForgotPasswordScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.ensureVisible(find.text('Send Code'));
    await tester.tap(find.text('Send Code'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reset-password screen validates code, length and match', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const ResetPasswordScreen(email: 'a@b.co')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('a@b.co'), findsOneWidget);

    await tester.ensureVisible(find.text('Reset Password'));
    await tester.tap(find.text('Reset Password'));
    await tester.pump();
    expect(find.text('Enter the 6-digit code.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.tap(find.text('Reset Password'));
    await tester.pump();
    expect(find.text('Password is required'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'short');
    await tester.tap(find.text('Reset Password'));
    await tester.pump();
    expect(find.text('Use at least 8 characters'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'long-enough-1');
    await tester.enterText(find.byType(TextFormField).at(1), 'different-1');
    await tester.tap(find.text('Reset Password'));
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Delete-account dialog asks for the password and can be cancelled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => DeleteAccountDialog.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pump();
    expect(find.text('Enter your password to continue.'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
