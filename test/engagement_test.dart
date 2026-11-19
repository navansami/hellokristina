import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hello_kristina/avatar/learner_look.dart';
import 'package:hello_kristina/main.dart';
import 'package:hello_kristina/feedback/learning_feedback.dart';
import 'package:hello_kristina/speech/serbian_speech.dart';

Question gap(String answer, String id) => Question('Complete the sentence',
    'Ovo je ___.', answer, [answer, 'voda', 'hleb'], 'This is $answer.',
    id: id, translation: 'This is $answer.', answerLanguage: 'sr');

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SerbianSpeech.debugSupported = false;
    learningFeedback.sounds = false;
    learningFeedback.vibration = false;
    learningFeedback.spokenWords = false;
  });

  group('daily log', () {
    test('counts XP for today only and remembers practice days', () {
      final monday = DateTime(2026, 11, 16, 9);
      var log = const DailyLog(goal: 20).record(12, monday);
      log = log.record(10, monday.add(const Duration(hours: 5)));
      expect(log.xpOn(monday), 22);
      expect(log.activeOn(monday), isTrue);
      final tuesday = monday.add(const Duration(days: 1));
      expect(log.xpOn(tuesday), 0);
      expect(log.activeOn(tuesday), isFalse);
      log = log.record(5, tuesday);
      expect(log.xpOn(tuesday), 5);
      expect(log.days, {'2026-11-16', '2026-11-17'});
      expect(log.withGoal(50).goal, 50);
    });

    test('keeps only the last 60 practice days', () {
      var log = const DailyLog();
      final start = DateTime(2026, 1, 1, 12);
      for (var i = 0; i < 70; i++) {
        log = log.record(1, start.add(Duration(days: i)));
      }
      expect(log.days.length, 60);
      expect(log.days.contains(dayKey(start)), isFalse);
    });
  });

  test('mistakes are missed items below 60% mastery, weakest first', () {
    final lesson = Lesson('cafe', 'Cafe', '', '', 'green', [
      gap('kafa', 'a'),
      gap('čaj', 'b'),
      gap('sok', 'c'),
      gap('pivo', 'd'),
    ]);
    final memory = {
      'a': [1, 1, 3], // 0.50: a mistake
      'b': [0, 2, 3], // 0.25: the weakest
      'c': [2, 1, 3], // 0.60: fixed
      'd': [3, 0, 3], // never missed
    };
    final mistakes = mistakeQuestions([lesson], memory);
    expect(mistakes.map((q) => q.id), ['b', 'a']);
    expect(mistakes.every((q) => !q.review), isTrue);
    expect(mistakesPassed([true, true, false]), isTrue);
    expect(mistakesPassed([true, false, false]), isFalse);
  });

  testWidgets('the words tab offers a mistakes session from three',
      (tester) async {
    var started = 0;
    Future<void> pump(int count) => tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WordsPage(
                done: const {},
                mistakes: count,
                onMistakes: () => started++))));
    await pump(2);
    expect(find.text('No mistakes to fix'), findsOneWidget);
    expect(find.text('2 to fix. A session opens at 3.'), findsOneWidget);
    await pump(4);
    expect(find.text('Fix your mistakes'), findsOneWidget);
    await tester.tap(find.text('START'));
    expect(started, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finishing a session that reaches the daily goal celebrates it',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: LessonPage(
            lesson: Lesson('goal', 'Coffee', '', '', 'green',
                List.filled(5, gap('kafa', 'g'))),
            dailyBefore: 15,
            dailyGoal: 20,
            onComplete: (_, __) async {})));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('kafa').last);
      await tester.pump();
      await tester.tap(find.text('Check'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 300));
    }
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.text('Daily goal reached!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the streak chip opens the week and the goal picker',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final previous = List<Lesson>.of(lessons);
    lessons = [Lesson('a', 'a', '', '👋', 'green', const [], unitTitle: 'U')];
    addTearDown(() => lessons = previous);
    int? chosen;
    final log = const DailyLog(goal: 20).record(8, DateTime.now());
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!),
        home: Scaffold(
            body: PathPage(
                done: const {},
                completedRounds: const {},
                reviewLessonId: null,
                xp: 0,
                streak: 3,
                daily: log,
                onGoal: (goal) async => chosen = goal,
                look: const LearnerLook(),
                onLesson: (_, __) {},
                onChat: () {},
                onProfile: () {}))));
    await tester.pump();
    expect(find.byTooltip('Daily goal: 8 / 20 XP'), findsOneWidget);
    await tester.tap(find.byTooltip('3-day streak'));
    await tester.pumpAndSettle();
    expect(find.text('3-day streak'), findsOneWidget);
    expect(find.text('You practised today. See you tomorrow!'), findsOneWidget);
    expect(find.text('8 / 20 XP'), findsOneWidget);
    await tester.tap(find.text('Intense'));
    await tester.pump();
    expect(chosen, 50);
    expect(find.text('8 / 50 XP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a cooled flame warns when today is still to do', (tester) async {
    final previous = List<Lesson>.of(lessons);
    lessons = [Lesson('a', 'a', '', '👋', 'green', const [], unitTitle: 'U')];
    addTearDown(() => lessons = previous);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!),
        home: Scaffold(
            body: PathPage(
                done: const {},
                completedRounds: const {},
                reviewLessonId: null,
                xp: 0,
                streak: 4,
                daily: const DailyLog().record(10, yesterday),
                look: const LearnerLook(),
                onLesson: (_, __) {},
                onChat: () {},
                onProfile: () {}))));
    await tester.pump();
    expect(find.byTooltip('Practise today to keep your 4-day streak'),
        findsOneWidget);
    expect(find.byTooltip('Daily goal: 0 / 20 XP'), findsOneWidget);
  });
}
