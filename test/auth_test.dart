import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hello_kristina/auth/auth_api.dart';
import 'package:hello_kristina/auth/auth_rules.dart';
import 'package:hello_kristina/main.dart';
import 'package:hello_kristina/feedback/learning_feedback.dart';

/// A fake server recording requests; [handler] answers them.
class FakeServer {
  final requests = <http.Request>[];
  http.Response Function(http.Request request) handler;
  FakeServer(this.handler);
  late final client = MockClient((request) async {
    requests.add(request);
    return handler(request);
  });
  Map<String, dynamic> body(int i) =>
      jsonDecode(requests[i].body) as Map<String, dynamic>;
}

http.Response json(int status, Object body) =>
    http.Response(jsonEncode(body), status,
        headers: {'content-type': 'application/json'});

const user = {'name': 'Ana', 'username': 'ana_s', 'email': 'ana@example.com'};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    learningFeedback.sounds = false;
    learningFeedback.vibration = false;
  });

  test('app and server share the same account rules', () {
    final cases = jsonDecode(File('scripts/auth-cases.json').readAsStringSync())
        as Map<String, dynamic>;
    final rules = {
      'name': nameError,
      'username': usernameError,
      'email': emailError,
      'password': passwordError,
    };
    for (final entry in cases.entries) {
      for (final pair in entry.value as List) {
        expect(rules[entry.key]!(pair[0] as String), pair[1],
            reason: '${entry.key}: "${pair[0]}"');
      }
    }
    expect(normalizeUsername(' @Ana.S '), 'ana.s');
  });

  Future<List<AuthSession>> pumpAuth(WidgetTester tester, FakeServer server,
      {String? resetToken, List<bool>? resets}) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sessions = <AuthSession>[];
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!),
        home: AuthPage(
            api: AuthApi((path) => Uri.parse('https://test$path'),
                client: server.client),
            resetToken: resetToken,
            onResetHandled: (changed) => resets?.add(changed),
            onSession: (session) async => sessions.add(session))));
    await tester.pump();
    return sessions;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Finder field(String label) => find.widgetWithText(TextField, label).first;

  testWidgets('signing up checks every field, then creates the account',
      (tester) async {
    final server = FakeServer((request) {
      if (request.method == 'GET') return json(200, {'available': true});
      return json(201, {'token': 't0k3n', 'user': user});
    });
    final sessions = await pumpAuth(tester, server);
    expect(find.text('GET STARTED'), findsOneWidget);
    expect(find.text('I ALREADY HAVE AN ACCOUNT'), findsOneWidget);
    await tester.tap(find.text('GET STARTED'));
    await settle(tester);
    expect(find.text('Create your account'), findsOneWidget);

    await tester.tap(find.text('CREATE ACCOUNT'));
    await settle(tester);
    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Usernames need at least 3 characters'), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Please accept to continue'), findsOneWidget);
    expect(server.requests, isEmpty);

    await tester.enterText(field('Your name'), 'Ana');
    await tester.enterText(field('Username'), 'Ana_S');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(server.requests.single.url.queryParameters['username'], 'ana_s');
    expect(find.byTooltip('Available'), findsOneWidget);
    await tester.enterText(field('Email'), 'ana@example.com');
    await tester.enterText(field('Password'), 'serbian2026');
    await tester.enterText(field('Confirm password'), 'serbian2025');
    await tester.pump();
    expect(find.text('Passwords don’t match'), findsOneWidget);
    await tester.enterText(field('Confirm password'), 'serbian2026');
    // Tick the box itself (the middle of the sentence is the terms link).
    await tester.tapAt(
        tester.getTopLeft(find.textContaining('I agree to the')) +
            const Offset(-20, 8));
    await tester.pump();
    await tester.tap(find.text('CREATE ACCOUNT'));
    await settle(tester);

    expect(sessions.single.token, 't0k3n');
    expect(sessions.single.remember, isTrue);
    final sent = server.body(1);
    expect(sent['username'], 'ana_s');
    expect(sent['acceptedTerms'], isTrue);
    expect(sent['remember'], isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a taken email shows under the email field', (tester) async {
    final server = FakeServer((request) => request.method == 'GET'
        ? json(200, {'available': true})
        : json(409, {
            'error': 'This email is already registered. Try logging in.',
            'field': 'email'
          }));
    await pumpAuth(tester, server);
    await tester.tap(find.text('GET STARTED'));
    await settle(tester);
    await tester.enterText(field('Your name'), 'Ana');
    await tester.enterText(field('Username'), 'ana_s');
    await tester.enterText(field('Email'), 'ana@example.com');
    await tester.enterText(field('Password'), 'serbian2026');
    await tester.enterText(field('Confirm password'), 'serbian2026');
    // Tick the box itself (the middle of the sentence is the terms link).
    await tester.tapAt(
        tester.getTopLeft(find.textContaining('I agree to the')) +
            const Offset(-20, 8));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('CREATE ACCOUNT'));
    await settle(tester);
    expect(find.text('This email is already registered. Try logging in.'),
        findsOneWidget);
  });

  testWidgets('logging in: wrong details explain, right ones get in',
      (tester) async {
    var attempts = 0;
    final server = FakeServer((request) => ++attempts == 1
        ? json(401, {'error': 'That email, username or password isn’t right'})
        : json(200, {'token': 'abc', 'user': user}));
    final sessions = await pumpAuth(tester, server);
    await tester.tap(find.text('I ALREADY HAVE AN ACCOUNT'));
    await settle(tester);
    expect(find.text('Welcome back!'), findsOneWidget);
    await tester.tap(find.text('LOG IN'));
    await settle(tester);
    expect(find.text('Enter your email or username'), findsOneWidget);
    expect(server.requests, isEmpty);

    await tester.enterText(field('Email or username'), 'ana_s');
    await tester.enterText(field('Password'), 'wrong1234');
    await tester.tap(find.text('LOG IN'));
    await settle(tester);
    expect(find.text('That email, username or password isn’t right'),
        findsOneWidget);
    expect(sessions, isEmpty);

    // Untick "Remember me": the session should end when the app closes.
    await tester.tap(find.text('Remember me'));
    await tester.pump();
    expect(find.text('Sign out when the app or tab is closed'), findsOneWidget);
    await tester.enterText(field('Password'), 'serbian2026');
    await tester.tap(find.text('LOG IN'));
    await settle(tester);
    expect(sessions.single.remember, isFalse);
    expect(server.body(1)['identifier'], 'ana_s');
    expect(server.body(1)['remember'], isFalse);
  });

  testWidgets('forgot password sends a link', (tester) async {
    final server = FakeServer((_) => json(200, {'ok': true}));
    await pumpAuth(tester, server);
    await tester.tap(find.text('I ALREADY HAVE AN ACCOUNT'));
    await settle(tester);
    await tester.tap(find.text('Forgot password?'));
    await settle(tester);
    await tester.enterText(field('Email'), 'ana@example.com');
    await tester.tap(find.text('SEND RESET LINK'));
    await settle(tester);
    expect(find.text('Check your inbox'), findsOneWidget);
    expect(server.body(0), {'action': 'forgot', 'email': 'ana@example.com'});
  });

  testWidgets('a reset link sets a new password', (tester) async {
    final server = FakeServer((_) => json(200, {'ok': true}));
    final resets = <bool>[];
    await pumpAuth(tester, server, resetToken: 'x' * 43, resets: resets);
    expect(find.text('Choose a new password'), findsOneWidget);
    await tester.enterText(field('New password'), 'nova2026pass');
    await tester.enterText(field('Confirm new password'), 'nova2026pass');
    await tester.tap(find.text('SAVE NEW PASSWORD'));
    await settle(tester);
    expect(find.text('Password changed'), findsOneWidget);
    expect(server.body(0)['action'], 'reset');
    expect(resets, [true]);
    await tester.tap(find.text('LOG IN'));
    await settle(tester);
    expect(find.text('Welcome back!'), findsOneWidget);
  });

  testWidgets('without an account the app opens on the front door',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const KristinaApp());
    for (var i = 0; i < 40 && find.text('GET STARTED').evaluate().isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('GET STARTED'), findsOneWidget);
    expect(find.text('Learn'), findsNothing);
  });
}
