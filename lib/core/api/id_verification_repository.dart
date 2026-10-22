import '../models/id_verification.dart';
import 'api_client.dart';

class IdVerificationRepository {
  IdVerificationRepository(this._client);

  final ApiClient _client;

  Future<IdVerification?> fetchLatest() async {
    final response = await _client.get('/id-verification');
    final data = response['data'];
    if (data == null) return null;
    return IdVerification.fromJson(data as Map<String, dynamic>);
  }

  Future<IdVerification> submit({
    required String documentType,
    required String photoPath,
  }) async {
    final response = await _client.postMultipart('/id-verification', {
      'document_type': documentType,
    }, filePath: photoPath);
    return IdVerification.fromJson(response['data'] as Map<String, dynamic>);
  }
}
