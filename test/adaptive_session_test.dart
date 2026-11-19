import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hello_kristina/main.dart';
import 'package:hello_kristina/avatar/learner_look.dart';
import 'package:hello_kristina/feedback/learning_feedback.dart';
import 'package:hello_kristina/speech/serbian_speech.dart';

const coffee = Question('Complete the sentence', 'Ovo je ___.', 'kafa',
    ['kafa', 'voda', 'hleb'], 'This is coffee.',
    translation: 'This is coffee.', answerLanguage: 'sr', focus: 'kafa');
const pairs = Question(
    'Match the pairs',
    'Tap the matching pairs',
    '',
    ['kafa|coffee', 'voda|water', 'hleb|bread', 'mleko|milk'],
    'Match each Serbian word with its meaning.',
    id: 'pairs:test',
    answerLanguage: 'sr');

Future<void> open(WidgetTester tester, List<Question> questions,
    {String kind = 'challenge'}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
      home: LessonPage(
          lesson: Lesson('t', 'Test', '', '', 'green', questions,
              kind: kind, minPassPercent: kind == 'challenge' ? 0 : 75),
          onComplete: (_, __) async {})));
  await tester.pump();
}

Future<void> check(WidgetTester tester, String word) async {
  await tester.tap(find.text(word).last);
  await tester.pump();
  await tester.tap(find.text('Check'));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> next(WidgetTester tester) async {
  await tester.tap(find.text('Continue'));
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

  testWidgets('a miss comes back once at the end, tagged as a mistake',
      (tester) async {
    await open(tester, [coffee.copy(id: 'a'), coffee.copy(id: 'b')]);
    await check(tester, 'voda');
    await next(tester);
    expect(find.text('MISTAKE'), findsNothing);
    await check(tester, 'kafa');
    await next(tester);
    // The retry of the first question.
    expect(find.text('MISTAKE'), findsOneWidget);
    await check(tester, 'voda');
    await next(tester);
    // A retry is never retried, so the session ends.
    expect(find.text('Back to course'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkpoints never add retries', (tester) async {
    await open(tester, [coffee.copy(id: 'a')], kind: 'checkpoint');
    await check(tester, 'voda');
    await next(tester);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('review exercises are labelled', (tester) async {
    await open(tester, [coffee.copy(id: 'a', review: true)]);
    expect(find.text('REVIEW'), findsOneWidget);
  });

  testWidgets('matching all pairs checks itself', (tester) async {
    await open(tester, [pairs]);
    expect(find.text('Tap the matching pairs'), findsOneWidget);
    for (final pair in pairs.options) {
      final parts = pair.split('|');
      await tester.tap(find.text(parts[0]));
      await tester.pump();
      await tester.tap(find.text(parts[1]));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Nicely done!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two wrong matches make the pairs game a miss', (tester) async {
    await open(tester, [pairs]);
    for (final wrong in [('kafa', 'water'), ('voda', 'bread')]) {
      await tester.tap(find.text(wrong.$1));
      await tester.pump();
      await tester.tap(find.text(wrong.$2));
      await tester.pump(const Duration(milliseconds: 500));
    }
    for (final pair in pairs.options) {
      final parts = pair.split('|');
      await tester.tap(find.text(parts[0]));
      await tester.pump();
      await tester.tap(find.text(parts[1]));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Let’s get this one.'), findsOneWidget);
    expect(find.textContaining('Answer:'), findsNothing);
  });

  testWidgets('a flawless session fills three ring segments', (tester) async {
    await open(tester, [
      for (var i = 0; i < 5; i++) coffee.copy(id: 'q$i'),
    ]);
    for (var i = 0; i < 5; i++) {
      await check(tester, 'kafa');
      await next(tester);
    }
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.text('Ring +3'), findsOneWidget);
  });

  testWidgets('units ahead of the learner offer a jump', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    lessons = [
      Lesson('a0', 'a0', '', '', 'green', const [], unitTitle: 'First'),
      Lesson('a1', 'a1', '', '', 'green', const [], unitTitle: 'First'),
      Lesson('b0', 'b0', '', '', 'green', const [], unitTitle: 'Second'),
    ];
    int? jumped;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(390, 800), disableAnimations: true),
            child: Scaffold(
                body: PathPage(
                    done: const {},
                    completedRounds: const {},
                    reviewLessonId: null,
                    xp: 0,
                    streak: 0,
                    look: const LearnerLook(),
                    onLesson: (_, __) {},
                    onJump: (unit) => jumped = unit,
                    onChat: () {},
                    onProfile: () {})))));
    await tester.pump();
    expect(find.text('JUMP HERE'), findsOneWidget);
    await tester.tap(find.text('JUMP HERE'));
    await tester.pumpAndSettle();
    expect(find.text('Jump to unit 2?'), findsOneWidget);
    await tester.tap(find.text('Start the test'));
    await tester.pumpAndSettle();
    // Passing the test on unit 1's lessons opens unit 2.
    expect(jumped, 0);
  });
}
