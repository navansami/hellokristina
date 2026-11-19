import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hello_kristina/main.dart';
import 'package:hello_kristina/feedback/learning_feedback.dart';
import 'package:hello_kristina/social/social_api.dart';

Map<String, Object?> person(String name, int xp,
        {bool youFollow = false, bool followsYou = false}) =>
    {
      'id': name,
      'name': name,
      'username': name.toLowerCase(),
      'xp': xp,
      'streak': 2,
      'level': 3,
      'youFollow': youFollow,
      'followsYou': followsYou,
    };

http.Response reply(Object body) => http.Response(jsonEncode(body), 200,
    headers: {'content-type': 'application/json'});

void main() {
  setUp(() {
    learningFeedback.sounds = false;
    learningFeedback.vibration = false;
  });

  test('time ago reads naturally', () {
    final now = DateTime(2026, 11, 19, 12);
    expect(timeAgo(now.subtract(const Duration(seconds: 20)), now), 'just now');
    expect(timeAgo(now.subtract(const Duration(minutes: 5)), now), '5m');
    expect(timeAgo(now.subtract(const Duration(hours: 3)), now), '3h');
    expect(timeAgo(now.subtract(const Duration(days: 2)), now), '2d');
    expect(timeAgo(DateTime(2026, 10, 1), now), '1 Oct');
  });

  testWidgets('follow people, see the leaderboard and cheer their wins',
      (tester) async {
    tester.view.physicalSize = const Size(420, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final requests = <http.Request>[];
    final now = DateTime.now().toUtc();
    final client = MockClient((request) async {
      requests.add(request);
      final path = request.url.path;
      final q = request.url.queryParameters['q'];
      if (path.endsWith('/friends') && request.method == 'GET' && q != null) {
        return reply({
          'results': [person('Mila', 80)]
        });
      }
      if (path.endsWith('/friends') && request.method == 'GET') {
        return reply({
          'following': [person('Bo', 300, youFollow: true, followsYou: true)],
          'followers': [
            person('Bo', 300, youFollow: true, followsYou: true),
            person('Cy', 50, followsYou: true),
          ],
        });
      }
      if (path.endsWith('/friends')) {
        final username = jsonDecode(request.body)['username'];
        return reply({
          'person':
              person(username == 'cy' ? 'Cy' : 'Mila', 80, youFollow: true)
        });
      }
      if (path.endsWith('/feed') && request.method == 'GET') {
        return reply({
          'items': [
            {
              'id': 'f1',
              'type': 'levelUp',
              'level': 4,
              'actorName': 'Bo',
              'actorUsername': 'bo',
              'likeCount': 1,
              'createdAt':
                  now.subtract(const Duration(hours: 2)).toIso8601String(),
            },
            {
              'id': 'f2',
              'type': 'streak',
              'streak': 7,
              'actorName': 'Ana',
              'mine': true,
              'createdAt': now.toIso8601String(),
            },
          ]
        });
      }
      return reply({'liked': true, 'likeCount': 2});
    });

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FriendsPage(
                token: 't',
                me: const {'name': 'Ana', 'username': 'ana'},
                xp: 120,
                client: client))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // No introduction card: the tab opens straight on search.
    expect(find.text('Friends & feed'), findsNothing);
    expect(find.text('Find friends by name or @username'), findsOneWidget);
    expect(find.text('@ana'), findsOneWidget);
    expect(find.text('1 following · 2 followers'), findsOneWidget);

    // Leaderboard: Bo (300 XP) ranks above you (120 XP).
    final bo = tester.getTopLeft(find.text('Bo').first).dy;
    final you = tester.getTopLeft(find.text('Ana (you)')).dy;
    expect(bo, lessThan(you));

    // Feed: a level-up and your own streak, with time ago.
    expect(find.textContaining('reached level 4', findRichText: true),
        findsOneWidget);
    expect(find.textContaining('hit a 7-day streak', findRichText: true),
        findsOneWidget);
    expect(find.text('2h'), findsOneWidget);

    // Cheer Bo's level-up.
    await tester.tap(find.bySemanticsLabel('Cheer, 1'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel('Cheered, 2'), findsOneWidget);
    expect(jsonDecode(requests.last.body), {'itemId': 'f1'});

    // Follow back Cy.
    // The section title and Cy's button.
    expect(find.text('FOLLOW BACK'), findsNWidgets(2));
    await tester.tap(find.bySemanticsLabel('FOLLOW BACK').last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
        requests.any((r) =>
            r.method == 'POST' &&
            r.url.path.endsWith('/friends') &&
            jsonDecode(r.body)['username'] == 'cy'),
        isTrue);

    // Search and follow someone new.
    await tester.enterText(find.byType(TextField), 'mi');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(requests.any((r) => r.url.queryParameters['q'] == 'mi'), isTrue);
    expect(find.text('Mila'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Follow'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel('Following'), findsOneWidget);
    expect(jsonDecode(requests.lastWhere((r) => r.method == 'POST').body),
        {'username': 'mila'});
    expect(tester.takeException(), isNull);
  });
}
