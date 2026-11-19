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

  // Account management: these need the signed-in [token].

  Future<Map<String, dynamic>> _account(
      String method, String token, Map<String, Object?> body) async {
    final request = http.Request(method, url('/api/auth/profile'))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      })
      ..body = jsonEncode(body);
    final streamed = await (client?.send(request) ?? request.send());
    return _read(await http.Response.fromStream(streamed));
  }

  Map<String, dynamic> _user(Map<String, dynamic> data) =>
      data['user'] as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateDetails(String token,
          {required String name, required String username}) =>
      _guard(() async => _user(await _account('PATCH', token, {
            'details': {'name': name.trim(), 'username': username.trim()}
          })));

  Future<Map<String, dynamic>> updateEmail(
          String token, String email, String currentPassword) =>
      _guard(() async => _user(await _account('PATCH', token,
          {'email': email.trim(), 'currentPassword': currentPassword})));

  /// Returns a fresh session: every other device is signed out.
  Future<AuthSession> changePassword(String token,
          {required String current,
          required String next,
          required bool remember}) =>
      _guard(() async {
        final data = await _account('PATCH', token, {
          'password': {'current': current, 'next': next},
          'remember': remember,
        });
        return AuthSession(data['token'] as String, _user(data), remember);
      });

  Future<AuthSession> signOutEverywhere(String token,
          {required bool remember}) =>
      _guard(() async {
        final data = await _account('PATCH', token,
            {'action': 'signOutEverywhere', 'remember': remember});
        return AuthSession(data['token'] as String, _user(data), remember);
      });

  Future<void> deleteAccount(String token, String currentPassword) =>
      _guard(() async {
        await _account('DELETE', token, {'currentPassword': currentPassword});
      });
}
