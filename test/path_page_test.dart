import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_kristina/avatar/learner_look.dart';
import 'package:hello_kristina/main.dart';

Lesson trailLesson(String id, String unit) =>
    Lesson(id, id, '', '👋', 'green', const [], unitTitle: unit, level: 'A1');

Future<void> pumpTrail(WidgetTester tester, Set<String> done, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(MaterialApp(
      theme: ThemeData.light(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!),
      home: Scaffold(
          body: PathPage(
              done: done,
              completedRounds: const {},
              reviewLessonId: null,
              xp: 0,
              streak: 0,
              look: const LearnerLook(),
              onLesson: (_, __) {},
              onChat: () {},
              onProfile: () {}))));
  await tester.pump();
}

void main() {
  final previous = List<Lesson>.of(lessons);
  setUp(() {
    lessons = [
      for (var i = 0; i < 4; i++) trailLesson('a$i', 'First conversations'),
      for (var i = 0; i < 6; i++) trailLesson('b$i', 'Everyday essentials'),
    ];
  });
  tearDown(() => lessons = previous);

  testWidgets('section title stays pinned while its lessons scroll',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await pumpTrail(tester, {}, const Size(320, 640));
    final title = find.text('First conversations');
    final pinned = tester.getTopLeft(title).dy;
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable)).position;
    position.jumpTo(160);
    await tester.pump();
    expect(tester.getTopLeft(title).dy, pinned);
    await tester.scrollUntilVisible(find.text('b0'), 100);
    final nextHeaderOffset = position.pixels +
        tester.getTopLeft(find.text('Everyday essentials')).dy -
        pinned;
    position.jumpTo(nextHeaderOffset + 20);
    await tester.pump();
    expect(tester.getTopLeft(find.text('Everyday essentials')).dy, pinned);
    expect(find.text('First conversations'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the open section title stays at the top', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await pumpTrail(
        tester, {'a0', 'a1', 'a2', 'a3', 'b0'}, const Size(390, 700));
    final title = find.text('Everyday essentials');
    final pinned = tester.getTopLeft(title).dy;
    expect(pinned, lessThan(160));
    expect(find.text('First conversations'), findsNothing);
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable)).position;
    position.jumpTo(position.pixels + 180);
    await tester.pump();
    expect(tester.getTopLeft(title).dy, pinned);
    expect(tester.takeException(), isNull);
  });

  testWidgets("the START bubble on a unit's first stop clears the banner",
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final done in [<String>{}, {'a0', 'a1', 'a2', 'a3'}]) {
      await pumpTrail(tester, done, const Size(390, 760));
      final banner = tester.getTopLeft(find.byType(CustomScrollView)).dy + 150;
      await tester.pump();
      final bubble = find.text('START');
      expect(bubble, findsOneWidget);
      expect(tester.getRect(bubble).top, greaterThanOrEqualTo(banner));
      expect(tester.takeException(), isNull);
    }
  });
}
