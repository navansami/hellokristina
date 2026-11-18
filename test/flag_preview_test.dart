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
    await tester.tap(find.byIcon(Icons.expand_more_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Serbian'), findsNothing);
    expect(find.text('For English speakers'), findsOneWidget);
    expect(find.text('Your courses'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Flag of Serbia')), findsWidgets);
  });
}
