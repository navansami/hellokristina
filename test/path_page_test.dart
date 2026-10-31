import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_kristina/main.dart';

Lesson trailLesson(String id, String unit) =>
    Lesson(id, id, '', '👋', 'green', const [], unitTitle: unit, level: 'A1');

Future<void> pumpTrail(WidgetTester tester, Set<String> done, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
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
              avatarFace: '🙂',
              avatarColor: const Color(0xFF49C0F8),
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
    position.jumpTo(112 + 4 * 148.0 + 30 + 40);
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
}
