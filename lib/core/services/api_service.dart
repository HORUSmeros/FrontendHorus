import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiService {
  ApiService({
    String? baseUrl,
    http.Client? httpClient,
  })  : baseUrl = (baseUrl ?? AppConfig.instance.normalizedBackendBaseUrl).trim(),
        _client = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  static const _timeout = Duration(seconds: 20);

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
      };

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = Uri.parse(baseUrl);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return base.replace(
      path: normalizedPath,
      queryParameters: _mapQueryParameters(queryParameters),
    );
  }

  Map<String, String?>? _mapQueryParameters(Map<String, dynamic>? queryParameters) {
    if (queryParameters == null) return null;
    return queryParameters.map((key, value) => MapEntry(key, _stringifyQueryValue(value)));
  }

  String? _stringifyQueryValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _client
        .get(_buildUri(path, queryParameters), headers: _headers)
        .timeout(_timeout);
    _throwOnError(response);
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? queryParameters, Object? body}) async {
    final response = await _client
        .post(
          _buildUri(path, queryParameters),
          headers: _headers,
          body: _encodeBody(body),
        )
        .timeout(_timeout);
    _throwOnError(response);
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? queryParameters, Object? body}) async {
    final response = await _client
        .put(
          _buildUri(path, queryParameters),
          headers: _headers,
          body: _encodeBody(body),
        )
        .timeout(_timeout);
    _throwOnError(response);
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? queryParameters, Object? body}) async {
    final response = await _client
        .patch(
          _buildUri(path, queryParameters),
          headers: _headers,
          body: _encodeBody(body),
        )
        .timeout(_timeout);
    _throwOnError(response);
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<void> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _client
        .delete(_buildUri(path, queryParameters), headers: _headers)
        .timeout(_timeout);
    _throwOnError(response);
  }

  String? _encodeBody(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    if (body is List<int>) return utf8.decode(body);

    final sanitized = _sanitizePayload(body);
    return jsonEncode(sanitized);
  }

  dynamic _sanitizePayload(dynamic value) {
    if (value is Map) {
      final result = <String, dynamic>{};
      value.forEach((key, rawValue) {
        if (key == 'trips') return;
        result[key.toString()] = _sanitizePayload(rawValue);
      });
      return result;
    }

    if (value is Iterable) {
      return value.map(_sanitizePayload).toList();
    }

    return value;
  }

  void _throwOnError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(
      statusCode: response.statusCode,
      message: response.body.isEmpty ? 'Request failed' : response.body,
      uri: response.request?.url,
    );
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message, this.uri});

  final int statusCode;
  final String message;
  final Uri? uri;

  @override
  String toString() => 'ApiException($statusCode): $message${uri == null ? '' : ', uri: $uri'}';
}
