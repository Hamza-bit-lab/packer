import 'api_client.dart';

class DeviceTokenRepository {
  DeviceTokenRepository(this._client);

  final ApiClient _client;

  Future<void> register({required String token, required String platform}) {
    return _client.post('/device-tokens', {
      'token': token,
      'platform': platform,
    });
  }

  Future<void> unregister(String token) {
    return _client.delete(
      '/device-tokens?token=${Uri.encodeQueryComponent(token)}',
    );
  }
}
