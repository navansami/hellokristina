import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hello_kristina/main.dart';
import 'package:hello_kristina/feedback/learning_feedback.dart';
import 'package:hello_kristina/speech/serbian_speech.dart';
import 'package:hello_kristina/widgets/animated_kristina.dart';

const q = Question('Complete the sentence', 'Ovo je ___.', 'kafa',
    ['kafa', 'voda', 'hleb'], 'This is coffee.',
    translation: 'This is coffee.', answerLanguage: 'sr');

Future<void> answer(WidgetTester tester, String word) async {
  await tester.tap(find.text(word).last);
  await tester.pump();
  await tester.tap(find.text('Check'));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SerbianSpeech.debugSupported = false;
    learningFeedback.sounds = false;
    learningFeedback.vibration = false;
    learningFeedback.spokenWords = false;
  });
  tearDown(() {});

  testWidgets('a run of correct answers shows a growing combo chip',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: LessonPage(
            lesson: Lesson('run', 'Run', '', '', 'green', List.filled(4, q)),
            onComplete: (_, __) async {})));
    await tester.pump();
    await answer(tester, 'kafa');
    expect(find.text('×1'), findsNothing);
    expect(find.text('+2 XP'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 300));
    await answer(tester, 'kafa');
    expect(find.text('×2'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 300));
    await answer(tester, 'voda');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('×2'), findsNothing);
    expect(find.text('+2 XP'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finishing a session counts XP up and levels up', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var submitted = <bool>[];
    await tester.pumpWidget(MaterialApp(
        home: LessonPage(
            lesson: Lesson('run', 'Coffee', '', '', 'green', List.filled(8, q)),
            startXp: 30,
            onComplete: (_, answers) async => submitted = answers)));
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await answer(tester, 'kafa');
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(submitted.length, 8);
    expect(find.text('Back to course'), findsOneWidget);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    // 8/8 first pass: 10 + 16 + perfect 5 + run 5 = 36 XP; 30 → 66 is level 2.
    expect(find.text('+36'), findsOneWidget);
    expect(find.text('LEVEL UP!  Level 2'), findsOneWidget);
    expect(find.text('Perfect +5'), findsOneWidget);
    expect(find.text('Run of 5 +5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the tutor stays still and settles with reduced motion',
      (tester) async {
    await tester.pumpWidget(const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: AnimatedKristina(mood: 'hot')))));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AnimatedKristina));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
