import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiClient {
  ApiClient({this.token, http.Client? client})
    : _client = client ?? http.Client();

  // Override with --dart-define=API_BASE_URL=... to test locally.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://zyntaxes.com/api/v1',
  );

  /// Website base (Terms/Privacy), derived from [baseUrl].
  static String get webBaseUrl => baseUrl.replaceFirst(RegExp(r'/api/v1$'), '');

  static const Duration _timeout = Duration(seconds: 10);

  // Uploads carry a photo, so they get longer on slow mobile networks.
  static const Duration _uploadTimeout = Duration(seconds: 60);

  // One shared client so connections are reused across requests.
  final http.Client _client;

  String? token;

  /// Called when a signed-in request gets a 401 (token revoked or expired).
  void Function()? onSessionExpired;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _send(
      () => _client.get(Uri.parse('$baseUrl$path'), headers: _headers),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _send(
      () => _client.patch(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  /// PATCH as multipart POST (`_method=PATCH`), since PHP can't parse it.
  Future<Map<String, dynamic>> patchMultipart(
    String path,
    Map<String, String> fields, {
    String? filePath,
    String fileField = 'file',
  }) async {
    return _multipart(
      path,
      fields,
      filePath: filePath,
      fileField: fileField,
      method: 'PATCH',
    );
  }

  /// POST with a multipart body, for create endpoints with an optional file.
  Future<Map<String, dynamic>> postMultipart(
    String path,
    Map<String, String> fields, {
    String? filePath,
    String fileField = 'photo',
  }) async {
    return _multipart(path, fields, filePath: filePath, fileField: fileField);
  }

  Future<Map<String, dynamic>> _multipart(
    String path,
    Map<String, String> fields, {
    String? filePath,
    required String fileField,
    String? method,
  }) async {
    final response = await _send(() async {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
        ..headers.addAll({
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        })
        ..fields.addAll(fields);

      if (method != null) {
        request.fields['_method'] = method;
      }

      if (filePath != null) {
        request.files.add(
          await http.MultipartFile.fromPath(fileField, filePath),
        );
      }

      final streamed = await _client.send(request);
      return http.Response.fromStream(streamed);
    }, timeout: _uploadTimeout);
    return _decode(response);
  }

  /// Set [expireSessionOn401] to false for calls that answer 401 to a wrong
  /// password (not an expired session), so they don't sign the user out.
  Future<void> delete(
    String path, {
    Map<String, dynamic>? body,
    bool expireSessionOn401 = true,
  }) async {
    final response = await _send(
      () => _client.delete(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    _decode(response, expireSessionOn401: expireSessionOn401);
  }

  /// Runs a request, turning network failures into a friendly [ApiException].
  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    Duration timeout = _timeout,
  }) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw ApiException('The request timed out. Please try again.');
    } on SocketException {
      throw ApiException(_offlineMessage);
    } on HandshakeException {
      throw ApiException(_offlineMessage);
    } on http.ClientException {
      throw ApiException(_offlineMessage);
    }
  }

  static const _offlineMessage =
      'Could not reach the server. Please check your connection.';

  Map<String, dynamic> _decode(
    http.Response response, {
    bool expireSessionOn401 = true,
  }) {
    final status = response.statusCode;

    // A proxy/server error page may not be JSON at all.
    Map<String, dynamic>? body = response.body.isEmpty ? {} : null;
    if (body == null) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } on FormatException {
        body = null;
      }
    }

    if (status >= 200 && status < 300) {
      if (body != null) return body;
      throw ApiException(
        'Unexpected response from the server.',
        statusCode: status,
      );
    }

    final message = body?['message'] is String
        ? body!['message'] as String
        : null;

    if (status == 422) {
      final errors = <String, List<String>>{};
      final raw = body?['errors'];
      if (raw is Map) {
        raw.forEach((key, value) {
          errors['$key'] = value is List
              ? [for (final item in value) '$item']
              : ['$value'];
        });
      }
      throw ApiException(
        message ?? 'Validation failed.',
        errors: errors,
        statusCode: 422,
      );
    }

    if (status == 401) {
      if (expireSessionOn401 && token != null) {
        onSessionExpired?.call();
        throw ApiException(
          'Your session has expired. Please sign in again.',
          statusCode: 401,
        );
      }
      throw ApiException(
        message ?? 'Invalid email or password.',
        statusCode: 401,
      );
    }

    throw ApiException(
      message ?? 'Something went wrong. Please try again.',
      statusCode: status,
    );
  }

  /// Fetches every page of a list endpoint (up to [maxPages]). [path] must
  /// already contain a query string.
  Future<List<dynamic>> getAllPages(String path, {int maxPages = 10}) async {
    final items = <dynamic>[];
    var page = 1;
    var lastPage = 1;

    do {
      final response = await get('$path&page=$page');
      items.addAll(response['data'] as List);
      final meta = response['meta'];
      lastPage = meta is Map ? (meta['last_page'] as num?)?.toInt() ?? 1 : 1;
      page++;
    } while (page <= lastPage && page <= maxPages);

    return items;
  }
}
