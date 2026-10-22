import '../models/feature_request.dart';
import 'api_client.dart';

class FeatureRequestRepository {
  FeatureRequestRepository(this._client);

  final ApiClient _client;

  Future<List<FeatureRequest>> fetchAll({String? search}) async {
    final query = (search != null && search.trim().isNotEmpty)
        ? '?search=${Uri.encodeQueryComponent(search.trim())}'
        : '';
    final response = await _client.get('/feature-requests$query');
    return (response['data'] as List)
        .map((item) => FeatureRequest.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<FeatureRequest> create({
    required String title,
    required String description,
  }) async {
    final response = await _client.post('/feature-requests', {
      'title': title,
      'description': description,
    });
    return FeatureRequest.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Same direction again removes the vote; the other direction switches it.
  Future<FeatureRequest> vote(int id, VoteDirection direction) async {
    final response = await _client.post('/feature-requests/$id/vote', {
      'direction': direction.name,
    });
    return FeatureRequest.fromJson(response['data'] as Map<String, dynamic>);
  }
}
