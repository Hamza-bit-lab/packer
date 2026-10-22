import '../models/route_alert.dart';
import 'api_client.dart';

class RouteAlertRepository {
  RouteAlertRepository(this._client);

  final ApiClient _client;

  Future<List<RouteAlert>> fetchMine() async {
    final response = await _client.get('/route-alerts');
    return (response['data'] as List)
        .map((item) => RouteAlert.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<RouteAlert> create({
    required RouteAlertWatchType watchType,
    required String fromCity,
    required String toCity,
  }) async {
    final response = await _client.post('/route-alerts', {
      'watch_type': watchType.name,
      'from_city': fromCity,
      'to_city': toCity,
    });
    return RouteAlert.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete('/route-alerts/$id');
}
