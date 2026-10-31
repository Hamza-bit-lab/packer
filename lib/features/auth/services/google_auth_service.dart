import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around [GoogleSignIn]'s one-time init and the sign-in flow —
/// the Web OAuth client below is only used as the token's audience for our
/// backend to verify against, not for any actual web login.
class GoogleAuthService {
  GoogleAuthService._();

  static const _webClientId =
      '489245827562-dc96b04hj5q92a4bbh3r1jf7i3rrtlpg.apps.googleusercontent.com';

  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
    _initialized = true;
  }

  /// Runs the native Google sign-in sheet and returns the ID token to send
  /// to our backend, or null if the user cancelled.
  static Future<String?> signIn() async {
    await _ensureInitialized();

    try {
      final account = await GoogleSignIn.instance.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }
}
