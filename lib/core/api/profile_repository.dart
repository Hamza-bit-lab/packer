import '../models/rating.dart';
import '../models/user.dart';
import 'api_client.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final ApiClient _client;

  Future<User> fetchPublicProfile(int userId) async {
    final response = await _client.get('/users/$userId');
    return User.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<Rating>> fetchRatings(int userId) async {
    final response = await _client.get('/users/$userId/ratings?per_page=50');
    return (response['data'] as List)
        .map((item) => Rating.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<User> update({
    String? name,
    String? phoneNumber,
    String? country,
    String? profilePicturePath,
  }) async {
    final response = await _client.patchMultipart(
      '/me',
      {
        if (name != null) 'name': name,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (country != null) 'country': country,
      },
      filePath: profilePicturePath,
      fileField: 'profile_picture',
    );
    return User.fromJson(response['data'] as Map<String, dynamic>);
  }
}
