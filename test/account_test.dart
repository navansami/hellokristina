import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hello_kristina/auth/auth_api.dart';
import 'package:hello_kristina/avatar/learner_look.dart';
import 'package:hello_kristina/main.dart';
import 'package:hello_kristina/feedback/learning_feedback.dart';

const ana = {
  'name': 'Ana',
  'username': 'ana_s',
  'email': 'ana@example.com',
};

http.Response reply(int status, Object body) => http.Response(
    jsonEncode(body), status,
    headers: {'content-type': 'application/json'});

class Harness {
  final requests = <http.Request>[];
  http.Response Function(http.Request) handler;
  Harness(this.handler);
  final users = <Map<String, dynamic>>[];
  final sessions = <AuthSession>[];
  var signedOut = 0, deleted = 0;
  Map<String, dynamic> body(int i) =>
      jsonDecode(requests[i].body) as Map<String, dynamic>;

  Future<void> pump(WidgetTester tester, {bool remembered = true}) async {
    tester.view.physicalSize = const Size(420, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = AuthApi((path) => Uri.parse('https://test$path'),
        client: MockClient((request) async {
      requests.add(request);
      return handler(request);
    }));
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!),
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AccountPage(
                                api: api,
                                token: 'tok',
                                user: ana,
                                remembered: remembered,
                                daily: const DailyLog(),
                                streak: 2,
                                look: const LearnerLook(),
                                onGoal: (_) async {},
                                onEditLook: () async => const LearnerLook(),
                                onUser: users.add,
                                onSession: (s) async => sessions.add(s),
                                onSignOut: () async => signedOut++,
                                onDeleted: () async => deleted++))),
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await settle(tester);
  }
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder field(String label) => find.widgetWithText(TextField, label).first;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    learningFeedback.sounds = false;
    learningFeedback.vibration = false;
  });

  testWidgets('editing name and username saves and shows the change',
      (tester) async {
    var calls = 0;
    final h = Harness((request) => ++calls == 1
        ? reply(409, {'error': 'That username is taken', 'field': 'username'})
        : reply(200, {
            'user': {...ana, 'name': 'Ana Petrović', 'username': 'ana.p'}
          }));
    await h.pump(tester);
    expect(find.text('Account settings'), findsOneWidget);
    expect(find.text('@ana_s'), findsWidgets);
    await tester.tap(find.text('Name'));
    await settle(tester);
    expect(find.text('Edit profile'), findsOneWidget);
    await tester.enterText(field('Your name'), 'Ana Petrović');
    await tester.enterText(field('Username'), 'x');
    await tester.tap(find.text('SAVE'));
    await tester.pump();
    expect(find.text('Usernames need at least 3 characters'), findsOneWidget);
    expect(h.requests, isEmpty);

    await tester.enterText(field('Username'), 'taken');
    await tester.tap(find.text('SAVE'));
    await settle(tester);
    expect(find.text('That username is taken'), findsOneWidget);

    await tester.enterText(field('Username'), '@Ana.P');
    await tester.tap(find.text('SAVE'));
    await settle(tester);
    expect(h.requests.last.method, 'PATCH');
    expect(h.requests.last.headers['Authorization'], 'Bearer tok');
    expect(h.body(1), {
      'details': {'name': 'Ana Petrović', 'username': 'ana.p'}
    });
    expect(h.users.single['name'], 'Ana Petrović');
    expect(find.text('Ana Petrović'), findsWidgets);
    expect(find.text('Profile updated'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing email needs the current password', (tester) async {
    final h = Harness((request) =>
        reply(403, {'error': 'That password isn’t right', 'field': 'currentPassword'}));
    await h.pump(tester);
    await tester.tap(find.text('Email'));
    await settle(tester);
    await tester.enterText(field('New email'), 'ana@new.rs');
    await tester.tap(find.text('SAVE EMAIL'));
    await tester.pump();
    expect(find.text('Enter your password'), findsOneWidget);
    await tester.enterText(field('Current password'), 'nope1234');
    await tester.tap(find.text('SAVE EMAIL'));
    await settle(tester);
    expect(find.text('That password isn’t right'), findsOneWidget);
    expect(h.body(0), {'email': 'ana@new.rs', 'currentPassword': 'nope1234'});
    expect(h.users, isEmpty);
  });

  testWidgets('changing the password keeps this device signed in',
      (tester) async {
    final h = Harness(
        (request) => reply(200, {'token': 'fresh', 'user': ana}));
    await h.pump(tester, remembered: false);
    await tester.tap(find.text('Password'));
    await settle(tester);
    await tester.enterText(field('Current password'), 'old12345');
    await tester.enterText(field('New password'), 'nova2026x');
    await tester.enterText(field('Confirm new password'), 'nova2026y');
    await tester.tap(find.text('CHANGE PASSWORD'));
    await tester.pump();
    expect(find.text('Passwords don’t match'), findsOneWidget);
    await tester.enterText(field('Confirm new password'), 'nova2026x');
    await tester.tap(find.text('CHANGE PASSWORD'));
    await settle(tester);
    expect(h.body(0), {
      'password': {'current': 'old12345', 'next': 'nova2026x'},
      'remember': false,
    });
    expect(h.sessions.single.token, 'fresh');
    expect(h.sessions.single.remember, isFalse);
    expect(find.text('Password changed. Other devices were signed out.'),
        findsOneWidget);
  });

  testWidgets('signing out other devices asks first', (tester) async {
    final h = Harness(
        (request) => reply(200, {'token': 'fresh2', 'user': ana}));
    await h.pump(tester);
    await tester.tap(find.text('Sign out others'));
    await settle(tester);
    expect(find.text('Sign out other devices?'), findsOneWidget);
    await tester.tap(find.text('SIGN OUT OTHER DEVICES'));
    await settle(tester);
    expect(h.body(0), {'action': 'signOutEverywhere', 'remember': true});
    expect(h.sessions.single.token, 'fresh2');
  });

  testWidgets('deleting needs the tick and the password', (tester) async {
    final h = Harness((request) => reply(200, {'ok': true}));
    await h.pump(tester);
    await tester.ensureVisible(find.text('Delete account'));
    await tester.tap(find.text('Delete account'));
    await settle(tester);
    expect(find.text('Delete your account?'), findsOneWidget);
    await tester.enterText(field('Your password'), 'serbian2026');
    await tester.tap(find.text('DELETE MY ACCOUNT'));
    await settle(tester);
    expect(h.requests, isEmpty, reason: 'disabled until ticked');
    await tester.tap(find.text('I understand this can’t be undone'));
    await tester.pump();
    await tester.tap(find.text('DELETE MY ACCOUNT'));
    await settle(tester);
    expect(h.requests.single.method, 'DELETE');
    expect(h.body(0), {'currentPassword': 'serbian2026'});
    expect(h.deleted, 1);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('signing out from settings asks, then leaves', (tester) async {
    final h = Harness((request) => reply(200, {}));
    await h.pump(tester);
    await tester.ensureVisible(find.text('SIGN OUT'));
    await tester.tap(find.text('SIGN OUT'));
    await settle(tester);
    await tester.tap(find.text('SIGN OUT').last);
    await settle(tester);
    expect(h.signedOut, 1);
    expect(find.text('Open'), findsOneWidget);
  });
}
