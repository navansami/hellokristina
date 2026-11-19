import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hello_kristina/avatar/avatar_editor.dart';
import 'package:hello_kristina/avatar/learner_look.dart';
import 'package:hello_kristina/main.dart';
import 'package:hello_kristina/feedback/learning_feedback.dart';
import 'package:hello_kristina/speech/serbian_speech.dart';

const q = Question('Complete the sentence', 'Ovo je ___.', 'kafa',
    ['kafa', 'voda', 'hleb'], 'This is coffee.',
    translation: 'This is coffee.', answerLanguage: 'sr');

/// A home screen with a button that opens [page].
Widget opener(Widget page) => MaterialApp(
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!),
    home: Builder(
        builder: (context) => Scaffold(
            body: TextButton(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => page)),
                child: const Text('Open')))));

/// Lets routes and sheets finish animating without waiting on the tutor.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SerbianSpeech.debugSupported = false;
    learningFeedback.sounds = false;
    learningFeedback.vibration = false;
    learningFeedback.spokenWords = false;
  });

  Future<void> openLesson(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(opener(LessonPage(
        lesson: Lesson('cafe', 'Cafe', '', '', 'green', List.filled(4, q)),
        onComplete: (_, __) async {})));
    await tester.tap(find.text('Open'));
    await settle(tester);
  }

  testWidgets('leaving before answering needs no confirmation',
      (tester) async {
    await openLesson(tester);
    await tester.tap(find.byTooltip('Leave lesson'));
    await settle(tester);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Wait, don’t go!'), findsNothing);
  });

  testWidgets('leaving mid-lesson asks first, by button or back',
      (tester) async {
    await openLesson(tester);
    await tester.tap(find.text('kafa').last);
    await tester.pump();
    await tester.tap(find.text('Check'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byTooltip('Leave lesson'));
    await settle(tester);
    expect(find.text('Wait, don’t go!'), findsOneWidget);
    expect(find.textContaining('answered 1 of 4'), findsOneWidget);
    await tester.tap(find.text('KEEP LEARNING'));
    await settle(tester);
    expect(find.text('Wait, don’t go!'), findsNothing);
    expect(find.text('Check'), findsOneWidget);

    // The system back button (Android, browser back) asks too.
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('Wait, don’t go!'), findsOneWidget);
    await tester.tap(find.text('LEAVE AND LOSE PROGRESS'));
    await settle(tester);
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a picked but unchecked answer also counts as progress',
      (tester) async {
    await openLesson(tester);
    await tester.tap(find.text('kafa').last);
    await tester.pump();
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.text('Wait, don’t go!'), findsOneWidget);
  });

  testWidgets('the avatar editor asks before discarding changes',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(opener(
        AvatarEditor(look: const LearnerLook(), onDone: (_) async {})));
    await tester.tap(find.text('Open'));
    await settle(tester);
    // No changes: close straight away.
    await tester.tap(find.byTooltip('Close'));
    await settle(tester);
    expect(find.text('Open'), findsOneWidget);

    await tester.tap(find.text('Open'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Skin tone 2'));
    await tester.pump();
    await tester.tap(find.byTooltip('Close'));
    await settle(tester);
    expect(find.text('Discard your changes?'), findsOneWidget);
    await tester.tap(find.text('KEEP EDITING'));
    await settle(tester);
    expect(find.text('Edit Avatar'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await settle(tester);
    await tester.tap(find.text('DISCARD CHANGES'));
    await settle(tester);
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signing out asks first', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var signedOut = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ProfilePage(
                user: const {
                  'name': 'Ana',
                  'username': 'ana',
                  'email': 'ana@example.com'
                },
                xp: 0,
                streak: 0,
                done: const {},
                look: const LearnerLook(),
                onAvatar: (_) async {},
                onClose: () {},
                onFriends: () {},
                onLogout: () async => signedOut++))));
    await tester.ensureVisible(find.text('SIGN OUT'));
    await settle(tester);
    await tester.tap(find.text('SIGN OUT'));
    await settle(tester);
    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.text('STAY SIGNED IN'));
    await settle(tester);
    expect(signedOut, 0);
    await tester.tap(find.text('SIGN OUT'));
    await settle(tester);
    await tester.tap(find.text('SIGN OUT').last);
    await settle(tester);
    expect(signedOut, 1);
    expect(tester.takeException(), isNull);
  });
}
