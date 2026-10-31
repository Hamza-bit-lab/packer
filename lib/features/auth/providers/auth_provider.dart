import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/auth_repository.dart';
import '../../../core/models/user.dart';
import '../../../core/services/push_notification_service.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider() : _client = ApiClient() {
    _repository = AuthRepository(_client);
    _client.onSessionExpired = _handleSessionExpired;
  }

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  // The token lives in the Keychain/Keystore; only the cached user profile
  // stays in SharedPreferences.
  static const _secureStorage = FlutterSecureStorage();

  final ApiClient _client;
  late final AuthRepository _repository;

  ApiClient get client => _client;

  AuthStatus status = AuthStatus.checking;
  User? user;
  bool isSubmitting = false;
  String? errorMessage;

  /// Restores the cached session; only logout or a real 401 ends it.
  Future<void> tryAutoLogin() async {
    final prefsFuture = SharedPreferences.getInstance();
    final secureTokenFuture = _readSecureToken();
    final prefs = await prefsFuture;
    final token = await secureTokenFuture ?? await _migrateLegacyToken(prefs);

    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _client.token = token;

    final cachedUserJson = prefs.getString(_userKey);
    if (cachedUserJson != null) {
      try {
        user = User.fromJson(
          jsonDecode(cachedUserJson) as Map<String, dynamic>,
        );
        status = AuthStatus.authenticated;
        notifyListeners();
      } catch (_) {
        // Corrupted cache — fall through to the network fetch below.
      }
    }

    try {
      final freshUser = await _repository.me();
      user = freshUser;
      status = AuthStatus.authenticated;
      await prefs.setString(_userKey, jsonEncode(freshUser.toJson()));
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _deleteStoredSession(prefs);
        _client.token = null;
        user = null;
        status = AuthStatus.unauthenticated;
      } else if (user == null) {
        // Nothing cached and the server rejected us for a non-auth reason.
        status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      // Network error: keep the cached state, else unauthenticated.
      if (user == null) status = AuthStatus.unauthenticated;
    }

    if (status == AuthStatus.authenticated) _registerPushToken();

    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) {
    return _submit(() => _repository.login(email: email, password: password));
  }

  Future<bool> loginWithGoogle(String idToken) {
    return _submit(() => _repository.loginWithGoogle(idToken));
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String country,
    required String password,
  }) {
    return _submit(
      () => _repository.register(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        country: country,
        password: password,
      ),
    );
  }

  Future<bool> _submit(Future<AuthResult> Function() action) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await action();
      _client.token = result.token;
      user = result.user;
      status = AuthStatus.authenticated;

      final prefs = await SharedPreferences.getInstance();
      await _saveToken(prefs, result.token);
      await prefs.setString(_userKey, jsonEncode(result.user.toJson()));
      _registerPushToken();

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (_) {
      errorMessage =
          'Could not reach the server. Please check your connection.';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  /// Best-effort; push setup failure shouldn't block the app.
  void _registerPushToken() {
    PushNotificationService.instance.registerForCurrentUser(_client).catchError(
      (e) {
        debugPrint('Could not register for push notifications: $e');
      },
    );
  }

  void setUser(User updated) {
    user = updated;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString(_userKey, jsonEncode(updated.toJson())),
    );
  }

  Future<void> logout() async {
    // Unregister the push token while the auth token is still valid.
    await PushNotificationService.instance.unregisterForCurrentUser(_client);

    try {
      await _repository.logout();
    } catch (_) {
      // Ignore network errors on logout — we clear local state regardless.
    }

    await _clearSession();
  }

  /// Deletes the account, then signs out; throws [ApiException] on failure.
  Future<void> deleteAccount(String password) async {
    await _repository.deleteAccount(password);
    // Server already removed the push token, nothing to unregister.
    await _clearSession();
  }

  /// The server rejected our token mid-session: sign out and leave any
  /// screens still open above the login page.
  void _handleSessionExpired() {
    if (status == AuthStatus.unauthenticated) return;
    _clearSession();
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  Future<void> _clearSession() async {
    _client.token = null;
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();

    await _deleteStoredSession(await SharedPreferences.getInstance());
  }

  Future<String?> _readSecureToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (_) {
      // Unreadable keystore entry (e.g. after a restore): drop it.
      try {
        await _secureStorage.delete(key: _tokenKey);
      } catch (_) {}
      return null;
    }
  }

  /// Saves the token securely, falling back to SharedPreferences only if the
  /// device's secure storage is unusable (so the user isn't logged out on
  /// every launch).
  Future<void> _saveToken(SharedPreferences prefs, String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      await prefs.remove(_tokenKey);
    } catch (_) {
      await prefs.setString(_tokenKey, token);
    }
  }

  /// Moves a token saved in plain SharedPreferences by an older version into
  /// secure storage, so existing users stay signed in.
  Future<String?> _migrateLegacyToken(SharedPreferences prefs) async {
    final legacy = prefs.getString(_tokenKey);
    if (legacy != null) await _saveToken(prefs, legacy);
    return legacy;
  }

  Future<void> _deleteStoredSession(SharedPreferences prefs) async {
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (_) {}
  }
}
