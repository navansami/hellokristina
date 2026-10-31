import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_kristina/avatar/avatar_editor.dart';
import 'package:hello_kristina/avatar/learner_look.dart';
import 'package:hello_kristina/avatar/learner_portrait.dart';
import 'package:hello_kristina/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a saved look ignores indexes outside the palettes', () {
    final look = LearnerLook.decode({
      'skin': 99,
      'body': 3,
      'hair': -1,
      'background': 0,
    });
    expect(look.skin, const LearnerLook().skin);
    expect(look.body, 3);
    expect(look.hair, const LearnerLook().hair);
    expect(look.background, 0);
  });

  testWidgets('the editor mixes a piece and saves it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    LearnerLook? saved;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AvatarEditor(
                            look: const LearnerLook(),
                            onDone: (look) async {
                              saved = look;
                            }))),
                child: const Text('Open editor')))));
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Avatar'), findsOneWidget);
    expect(find.text('Skin tone'), findsOneWidget);
    expect(find.text('😊'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Skin tone 2'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Hair'));
    await tester.pump();
    expect(find.text('Hairstyle'), findsOneWidget);
    expect(find.text('Main hair color'), findsOneWidget);
    final hairstyle = find.bySemanticsLabel('Hairstyle 4');
    await tester.scrollUntilVisible(
        hairstyle,
        240,
        scrollable: find
            .descendant(
                of: find.byType(AvatarEditor), matching: find.byType(Scrollable))
            .last);
    await tester.pumpAndSettle();
    await tester.tap(hairstyle);
    await tester.pump();
    await tester.tap(find.text('DONE'));
    await tester.pumpAndSettle();
    expect(saved?.skin, 1);
    expect(saved?.hair, 3);
    expect(find.byType(LearnerPortrait), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile shows the portrait instead of an emoji', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ProfilePage(
                user: const {
                  'name': 'Navan Sami',
                  'username': 'navan',
                  'createdAt': '2023-04-01T00:00:00.000Z',
                  'email': 'navan@example.com'
                },
                xp: 40,
                streak: 6,
                done: const {'hello'},
                look: const LearnerLook(),
                onAvatar: (_) async {},
                onClose: () {},
                onFriends: () {},
                onAuth: (_, __, ___, ____, _____) async {},
                onLogout: () async {}))));
    await tester.pump();
    expect(find.text('Navan Sami'), findsOneWidget);
    expect(find.text('Learning since 2023'), findsOneWidget);
    expect(find.textContaining('JOINED 2023'), findsOneWidget);
    expect(find.text('ADD FRIENDS'), findsOneWidget);
    expect(find.text('EDIT YOUR LOOK'), findsOneWidget);
    expect(find.byType(LearnerPortrait), findsOneWidget);
    expect(find.text('😊'), findsNothing);
    await tester.tap(find.text('EDIT YOUR LOOK'));
    await tester.pumpAndSettle();
    expect(find.text('Skin tone'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
