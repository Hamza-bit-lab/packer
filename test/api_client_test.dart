import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pack_and_carry/core/api/api_client.dart';
import 'package:pack_and_carry/core/api/api_exception.dart';

ApiClient _client(
  Future<http.Response> Function(http.Request) handler, {
  String? token = 't',
}) => ApiClient(token: token, client: MockClient(handler));

void main() {
  test('an HTML error page becomes an ApiException, not a crash', () async {
    final client = _client((_) async => http.Response('<html>Bad</html>', 502));

    expect(
      client.get('/x'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 502)),
    );
  });

  test('a network failure becomes a friendly ApiException', () async {
    final client = _client((_) async => throw const SocketException('down'));

    expect(
      client.get('/x'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('check your connection'),
        ),
      ),
    );
  });

  test('a 401 on a signed-in request expires the session once', () async {
    var expired = 0;
    final client = _client((_) async => http.Response('{}', 401))
      ..onSessionExpired = () => expired++;

    await expectLater(client.get('/me'), throwsA(isA<ApiException>()));
    expect(expired, 1);
  });

  test(
    'a 401 while logged out is a bad login, not an expired session',
    () async {
      var expired = 0;
      final client = _client(
        (_) async => http.Response('{"message":"Bad credentials"}', 401),
        token: null,
      )..onSessionExpired = () => expired++;

      await expectLater(
        client.post('/auth/login', {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Bad credentials',
          ),
        ),
      );
      expect(expired, 0);
    },
  );

  test('a wrong password on delete does not sign the user out', () async {
    var expired = 0;
    final client = _client((_) async => http.Response('{}', 401))
      ..onSessionExpired = () => expired++;

    await expectLater(
      client.delete('/me', expireSessionOn401: false),
      throwsA(isA<ApiException>()),
    );
    expect(expired, 0);
  });

  test('getAllPages walks every page', () async {
    final requested = <String>[];
    final client = _client((request) async {
      requested.add(request.url.query);
      final page = int.parse(request.url.queryParameters['page']!);
      return http.Response(
        '{"data":[$page],"meta":{"current_page":$page,"last_page":3}}',
        200,
      );
    });

    final items = await client.getAllPages('/trips?per_page=50');

    expect(items, [1, 2, 3]);
    expect(requested.length, 3);
  });
}
