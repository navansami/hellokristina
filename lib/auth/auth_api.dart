import 'dart:convert';

import 'package:http/http.dart' as http;

/// A failed account request: [field] names the form field to blame, if any.
class AuthError implements Exception {
  final String message;
  final String? field;
  const AuthError(this.message, [this.field]);
  @override
  String toString() => message;
}

/// A signed-in session.
class AuthSession {
  final String token;
  final Map<String, dynamic> user;
  final bool remember;
  const AuthSession(this.token, this.user, this.remember);
}

/// The account endpoints. Pass a [client] in tests.
class AuthApi {
  final Uri Function(String path) url;
  final http.Client? client;
  const AuthApi(this.url, {this.client});

  Future<http.Response> _post(String path, Map<String, Object?> body) =>
      (client?.post ?? http.post)(url(path),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body));

  Map<String, dynamic> _read(http.Response response) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const AuthError('Something went wrong. Please try again.');
    }
    if (response.statusCode >= 400) {
      throw AuthError(
          (data['error'] ?? 'Something went wrong. Please try again.')
              .toString(),
          data['field'] as String?);
    }
    return data;
  }

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on AuthError {
      rethrow;
    } catch (_) {
      throw const AuthError(
          'Can’t reach Hello Kristina. Check your connection and try again.');
    }
  }

  Future<AuthSession> signUp(
          {required String name,
          required String username,
          required String email,
          required String password,
          required bool remember}) =>
      _guard(() async {
        final data = _read(await _post('/api/auth/register', {
          'name': name.trim(),
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
          'acceptedTerms': true,
          'remember': remember,
        }));
        return AuthSession(data['token'] as String,
            data['user'] as Map<String, dynamic>, remember);
      });

  Future<AuthSession> logIn(
          {required String identifier,
          required String password,
          required bool remember}) =>
      _guard(() async {
        final data = _read(await _post('/api/auth/login', {
          'identifier': identifier.trim(),
          'password': password,
          'remember': remember,
        }));
        return AuthSession(data['token'] as String,
            data['user'] as Map<String, dynamic>, remember);
      });

  /// Null when the username is free, otherwise the reason it isn't.
  Future<String?> usernameProblem(String username) => _guard(() async {
        final response = await (client?.get ?? http.get)(url(
            '/api/auth/register?username=${Uri.encodeQueryComponent(username.trim())}'));
        final data = _read(response);
        return data['available'] == true
            ? null
            : (data['error'] ?? 'That username is taken').toString();
      });

  Future<void> forgotPassword(String email) => _guard(() async {
        _read(await _post(
            '/api/auth/login', {'action': 'forgot', 'email': email.trim()}));
      });

  Future<void> resetPassword(String token, String password) => _guard(() async {
        _read(await _post('/api/auth/login',
            {'action': 'reset', 'token': token, 'password': password}));
      });
}
