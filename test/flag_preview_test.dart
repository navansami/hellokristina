import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_kristina/avatar/learner_look.dart';
import 'package:hello_kristina/main.dart';

void main() {
  testWidgets('the course selector identifies the current course with its flag',
      (tester) async {
    final previous = List<Lesson>.of(lessons);
    addTearDown(() => lessons = previous);
    lessons = [Lesson('a', 'Hello', '', '👋', 'green', const [])];
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            body: RepaintBoundary(
                key: const ValueKey('page'),
                child: PathPage(
                    done: const {},
                    completedRounds: const {},
                    reviewLessonId: null,
                    xp: 12,
                    streak: 3,
                    look: const LearnerLook(),
                    onLesson: (_, __) {},
                    onChat: () {},
                    onProfile: () {})))));
    await tester.pump();
    final selector = find
        .ancestor(
            of: find.byIcon(Icons.expand_more_rounded),
            matching: find.byType(InkWell))
        .first;
    expect(find.descendant(of: selector, matching: find.byType(Text)),
        findsNothing);
    expect(find.bySemanticsLabel(RegExp('Flag of Serbia')), findsOneWidget);
    expect(find.text('Serbian'), findsNothing);
    await tester.tap(find.byIcon(Icons.expand_more_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    // The drop-down: course tiles, the level bar and practice shortcuts.
    expect(find.text('Serbian'), findsOneWidget);
    expect(find.text('From English'), findsOneWidget);
    expect(find.text('More soon'), findsOneWidget);
    expect(find.text('A1'), findsOneWidget);
    expect(find.text('A2'), findsOneWidget);
    expect(find.text('0 / 1 lessons'), findsOneWidget);
    expect(find.text('12 XP'), findsOneWidget);
    expect(find.text('Keep practising'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Flag of Serbia')), findsWidgets);
    await tester.tap(find.text('ABOUT YOUR LEVEL'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('CEFR scale'), findsOneWidget);
    // Tapping the dimmed trail closes it again.
    await tester.tapAt(const Offset(200, 760));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Keep practising'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat in the drop-down opens the chat', (tester) async {
    final previous = List<Lesson>.of(lessons);
    addTearDown(() => lessons = previous);
    lessons = [Lesson('a', 'Hello', '', '👋', 'green', const [])];
    var chats = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PathPage(
                done: const {},
                completedRounds: const {},
                reviewLessonId: null,
                xp: 0,
                streak: 0,
                look: const LearnerLook(),
                onLesson: (_, __) {},
                onChat: () => chats++,
                onProfile: () {}))));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.expand_more_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Chat').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(chats, 1);
    expect(find.text('Keep practising'), findsNothing);
  });
}
