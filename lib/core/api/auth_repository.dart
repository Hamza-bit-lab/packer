import '../models/user.dart';
import 'api_client.dart';

class AuthResult {
  AuthResult({required this.user, required this.token});

  final User user;
  final String token;
}

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<AuthResult> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String country,
    required String password,
  }) async {
    final response = await _client.post('/auth/register', {
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'country': country,
      'password': password,
      'password_confirmation': password,
    });

    return AuthResult(
      user: User.fromJson(response['user'] as Map<String, dynamic>),
      token: response['token'] as String,
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post('/auth/login', {
      'email': email,
      'password': password,
    });

    return AuthResult(
      user: User.fromJson(response['user'] as Map<String, dynamic>),
      token: response['token'] as String,
    );
  }

  Future<AuthResult> loginWithGoogle(String idToken) async {
    final response = await _client.post('/auth/google', {'id_token': idToken});

    return AuthResult(
      user: User.fromJson(response['user'] as Map<String, dynamic>),
      token: response['token'] as String,
    );
  }

  Future<User> me() async {
    final response = await _client.get('/me');
    return User.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> logout() => _client.post('/auth/logout', {});

  Future<String> resendVerificationEmail() async {
    final response = await _client.post('/auth/resend-verification', {});
    return response['message'] as String? ?? 'Verification code sent.';
  }

  /// Emails a 6-digit reset code; never reveals if the email exists.
  Future<String> forgotPassword(String email) async {
    final response = await _client.post('/auth/forgot-password', {
      'email': email,
    });
    return response['message'] as String? ?? 'Reset code sent.';
  }

  Future<String> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    final response = await _client.post('/auth/reset-password', {
      'email': email,
      'code': code,
      'password': password,
      'password_confirmation': password,
    });
    return response['message'] as String? ?? 'Password updated.';
  }

  /// Permanently deletes the signed-in account.
  Future<void> deleteAccount(String password) => _client.delete(
    '/me',
    body: {'password': password},
    expireSessionOn401: false,
  );

  Future<User> verifyEmail(String code) async {
    final response = await _client.post('/auth/verify-email', {'code': code});
    return User.fromJson(response['user'] as Map<String, dynamic>);
  }
}
