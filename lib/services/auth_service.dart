
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _baseUrl =
      'https://fullstact-e-com-platform.onrender.com/api/v1';

  static const String _registerPath = '/users/register/';
  static const String _loginPath = '/users/token/';
  static const String _refreshPath = '/users/token/refresh/';
  static const String _mePath = '/users/me/';

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _accessKey = 'vintonstore_access_token';
  static const String _refreshKey = 'vintonstore_refresh_token';

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> get _jsonHeaders => const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  Map<String, dynamic> _decodeResponse(http.Response response) {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is List) {
      return {'results': decoded};
    }

    return {};
  }

  String _errorMessage(
    http.Response response,
    Map<String, dynamic> data,
  ) {
    final detail = data['detail'] ??
        data['message'] ??
        data['error'];

    if (detail != null) {
      return detail.toString();
    }

    final errors = data.entries
        .map((entry) {
          final value = entry.value;

          if (value is List) {
            return '${entry.key}: ${value.join(', ')}';
          }

          return '${entry.key}: $value';
        })
        .join('\n');

    if (errors.isNotEmpty) {
      return errors;
    }

    switch (response.statusCode) {
      case 400:
        return 'Please check the information you entered.';
      case 401:
        return 'Invalid credentials or your session has expired.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested API endpoint was not found.';
      case 429:
        return 'Too many requests. Please try again later.';
      default:
        if (response.statusCode >= 500) {
          return 'The server encountered an error. Please try again later.';
        }

        return 'Request failed with HTTP ${response.statusCode}.';
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String firstName = '',
    String lastName = '',
  }) async {
    final response = await http
        .post(
          _uri(_registerPath),
          headers: _jsonHeaders,
          body: jsonEncode({
            'username': username.trim(),
            'email': email.trim(),
            'password': password,
            'password_confirm': passwordConfirm,
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
          }),
        )
        .timeout(const Duration(seconds: 60));

    final data = _decodeResponse(response);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(_errorMessage(response, data));
    }

    return data;
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await http
        .post(
          _uri(_loginPath),
          headers: _jsonHeaders,
          body: jsonEncode({
            'username': username.trim(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 60));

    final data = _decodeResponse(response);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(_errorMessage(response, data));
    }

    final access = data['access']?.toString();
    final refresh = data['refresh']?.toString();

    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
      throw Exception(
        'Login succeeded, but the server did not return '
        'the expected access and refresh tokens.',
      );
    }

    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: _accessKey);
  }

  Future<String?> getRefreshToken() {
    return _storage.read(key: _refreshKey);
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    var access = await getAccessToken();

    if (access == null || access.isEmpty) {
      throw Exception('Please sign in first.');
    }

    var response = await http
        .get(
          _uri(_mePath),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $access',
          },
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 401) {
      access = await refreshAccessToken();

      response = await http
          .get(
            _uri(_mePath),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $access',
            },
          )
          .timeout(const Duration(seconds: 60));
    }

    final data = _decodeResponse(response);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(_errorMessage(response, data));
    }

    return data;
  }

  Future<String> refreshAccessToken() async {
    final refresh = await getRefreshToken();

    if (refresh == null || refresh.isEmpty) {
      await logout();
      throw Exception('Your session has expired. Please sign in again.');
    }

    final response = await http
        .post(
          _uri(_refreshPath),
          headers: _jsonHeaders,
          body: jsonEncode({'refresh': refresh}),
        )
        .timeout(const Duration(seconds: 60));

    final data = _decodeResponse(response);
    final access = data['access']?.toString();

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        access == null ||
        access.isEmpty) {
      await logout();
      throw Exception(
        'Your session has expired. Please sign in again.',
      );
    }

    await _storage.write(key: _accessKey, value: access);

    return access;
  }

  Future<void> logout() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<bool> isLoggedIn() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();

    return access != null &&
        access.isNotEmpty &&
        refresh != null &&
        refresh.isNotEmpty;
  }
}
