import '../models/user.dart';
import 'api_client.dart';

class BlockRepository {
  BlockRepository(this._client);

  final ApiClient _client;

  Future<List<User>> fetchBlocked() async {
    final response = await _client.get('/blocks');
    return (response['data'] as List)
        .map((item) => User.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> block(int userId) => _client.post('/users/$userId/block', {});

  Future<void> unblock(int userId) => _client.delete('/users/$userId/block');
}
