import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_kristina/main.dart';
import 'package:hello_kristina/widgets/word_hints.dart';

final catalog =
    jsonDecode(File('curriculum/serbian-en.v1.json').readAsStringSync())
        as Map<String, dynamic>;
final questions = (catalog['units'] as List)
    .expand((u) => u['lessons'] as List)
    .expand((l) => l['challenges'] as List)
    .cast<Map<String, dynamic>>()
    .toList();
Question parse(Map<String, dynamic> q) => Question(q['type'], q['prompt'],
    q['answer'], (q['options'] as List).cast<String>(), q['explanation'],
    audioText: q['audioText'] ?? '',
    audioAsset: q['audio'] ?? '',
    translation: q['translation'] ?? '',
    answerLanguage: q['answerLanguage'] ?? '');
Future<void> screen(WidgetTester tester, Question q, Size size,
    {double keyboard = 0, bool guide = false}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: LessonPage(
          lesson: Lesson('test', 'Viewport lesson', 'Test', '', 'green', [q],
              theoryTitle: 'A lesson guide',
              theoryBody: guide
                  ? 'Learn familiar words in both Serbian scripts. Tap a speaker to hear the pronunciation.'
                  : '',
              vocabulary: const [
                ['Ja sam', 'Ја сам', 'I am', 'yah sahm', ''],
                ['Hvala', 'Хвала', 'Thank you', 'hvah-lah', ''],
                ['Zdravo', 'Здраво', 'Hello', 'zdrah-voh', '']
              ]),
          onComplete: (_, __) async {})));
  await tester.pump(const Duration(milliseconds: 400));
}

void clean(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  tester.view.resetViewInsets();
}

void main() {
  final types = questions.map((q) => q['type'] as String).toSet();
  for (final type in types) {
    final candidates = questions.where((q) => q['type'] == type).toList()
      ..sort((a, b) => (b['prompt'].length + b['options'].join(' ').length)
          .compareTo(a['prompt'].length + a['options'].join(' ').length));
    for (final size in [
      const Size(320, 568),
      const Size(360, 640),
      const Size(390, 700)
    ]) {
      testWidgets('$type fits ${size.width}x${size.height}', (tester) async {
        addTearDown(() => clean(tester));
        final q = parse(candidates.first);
        await screen(tester, q, size);
        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsNothing);
        final check = tester.getRect(find.text('CHECK'));
        expect(check.bottom, lessThan(size.height));
        if (q.type != 'Type the answer' && q.type != 'Listen and type') {
          final last = tester.getRect(find
              .text(q.type == 'Choose the image'
                  ? q.options.last.split(' ').skip(1).join(' ')
                  : q.options.last)
              .last);
          expect(last.bottom, lessThan(check.top));
          await tester.tap(find
              .text(q.type == 'Choose the image'
                  ? q.options.first.split(' ').skip(1).join(' ')
                  : q.options.first)
              .last);
          await tester.pump();
        } else {
          await tester.enterText(find.byType(TextField), q.answer);
          await tester.pump();
        }
        await tester.tap(find.text('CHECK'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.text('CONTINUE'), findsOneWidget);
        expect(tester.getRect(find.text('CONTINUE')).bottom,
            lessThan(size.height));
      });
    }
  }
  for (final correct in [true, false]) {
    for (final size in [const Size(320, 568), const Size(390, 700)]) {
      testWidgets('feedback overlays without moving answers $correct $size',
          (tester) async {
        addTearDown(() => clean(tester));
        const q = Question(
            'Choose the meaning',
            'Ja sam Kristina.',
            'I am Kristina.',
            [
              'I am Kristina.',
              'Hello Kristina.',
              'You are Kristina.',
              'Where is Kristina?'
            ],
            'Ja sam means I am.',
            audioText: 'Ja sam Kristina.');
        await screen(tester, q, size);
        final tiles = q.options
            .map((option) => find.byWidgetPredicate((widget) =>
                widget is Semantics && widget.properties.label == option))
            .toList();
        await tester.tap(find.text(correct ? q.answer : q.options.last));
        await tester.pump();
        final before = tiles.map(tester.getRect).toList();
        final prompt = tester.getRect(find.text('Ja'));
        await tester.tap(find.text('CHECK'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text(correct ? 'Nicely done!' : 'Let’s get this one.'),
            findsOneWidget);
        expect(tiles.map(tester.getRect).toList(), before);
        expect(tester.getRect(find.text('Ja')), prompt);
        expect(tester.getRect(find.text('CONTINUE')).bottom,
            lessThan(size.height));
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('sentence completion uses Serbian words and previews the choice',
      (tester) async {
    addTearDown(() => clean(tester));
    const q = Question('Complete the sentence', 'Ovo je ___.', 'kafa',
        ['kafa', 'voda', 'stanica'], 'Ovo je kafa. — This is coffee.',
        translation: 'This is coffee.');
    await screen(tester, q, const Size(360, 640));
    expect(find.text('Complete the sentence'), findsOneWidget);
    expect(find.text('Meaning: This is coffee.'), findsOneWidget);
    await tester.tap(find.text('kafa'));
    await tester.pump();
    expect(find.text('kafa.'), findsOneWidget);
    await tester.tap(find.text('CHECK'));
    await tester.pump();
    expect(find.text('Nicely done!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('word tiles preserve duplicates and can be reordered',
      (tester) async {
    addTearDown(() => clean(tester));
    const q = Question('Arrange the words', 'Kako ste?', 'How do you do',
        ['do', 'you', 'How', 'do', 'bread'], 'Build the English greeting.');
    await screen(tester, q, const Size(360, 640));
    for (final i in [2, 0, 1, 3]) {
      await tester.tap(find.byKey(ValueKey('bank-token-$i')));
      await tester.pump();
    }
    List<String?> selectedWords() => List.generate(
        4,
        (i) => tester
            .widget<Text>(find
                .descendant(
                    of: find.byKey(ValueKey('answer-token-$i')),
                    matching: find.byType(Text))
                .first)
            .data);
    expect(selectedWords(), ['How', 'do', 'you', 'do']);
    Future<void> move(int from, int to) async {
      final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(ValueKey('answer-token-$from'))));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture
          .moveTo(tester.getCenter(find.byKey(ValueKey('answer-token-$to'))));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 200));
    }

    await move(3, 0);
    expect(selectedWords(), ['do', 'How', 'do', 'you']);
    await move(0, 3);
    expect(selectedWords(), ['How', 'do', 'you', 'do']);
    expect(find.text('bread'), findsOneWidget);
    await tester.tap(find.text('CHECK'));
    await tester.pump();
    expect(find.text('Nicely done!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('typing keeps input and CHECK above the keyboard',
      (tester) async {
    addTearDown(() => clean(tester));
    await screen(
        tester,
        const Question('Type the answer', 'Write “thank you” in Serbian',
            'Hvala', [], 'Hvala means thank you.'),
        const Size(390, 640),
        keyboard: 260);
    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.byType(TextField)).height, greaterThan(40));
    expect(tester.getRect(find.text('CHECK')).bottom, lessThan(380));
  });
  testWidgets('prompt hint opens without selecting an answer', (tester) async {
    addTearDown(() => clean(tester));
    await screen(
        tester,
        const Question(
            'Choose the meaning',
            'Ja sam Kristina.',
            'I am Kristina.',
            ['I am Kristina.', 'Hello', 'Thanks', 'Goodbye'],
            'Ja sam means I am.',
            audioText: 'Ja sam Kristina.'),
        const Size(360, 640));
    await tester.tap(find.text('Ja'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('I am'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('guide uses pages and fits without vertical scrolling',
      (tester) async {
    addTearDown(() => clean(tester));
    await screen(tester, parse(questions.first), const Size(320, 568),
        guide: true);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Next guide page'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Hvala'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('completion fits a small viewport', (tester) async {
    addTearDown(() => clean(tester));
    await screen(
        tester,
        const Question(
            'Choose the meaning',
            'Hvala',
            'Thank you',
            ['Thank you', 'Hello', 'Goodbye', 'Please'],
            'Hvala means thank you.'),
        const Size(320, 568));
    await tester.tap(find.text('Thank you'));
    await tester.pump();
    await tester.tap(find.text('CHECK'));
    await tester.pump();
    await tester.tap(find.text('CONTINUE'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('BACK TO THE TRAIL'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('listening prompt does not reveal the transcript',
      (tester) async {
    addTearDown(() => clean(tester));
    await screen(
        tester,
        const Question(
            'Listen and type', 'Listen', 'Zdravo', [], 'Zdravo means hello.',
            audioText: 'Zdravo'),
        const Size(360, 640));
    expect(find.text('Zdravo'), findsNothing);
    expect(find.bySemanticsLabel('Hint for Zdravo'), findsNothing);
  });
  test('word hints respect phrases and unknown words', () {
    const vocab = [
      ['Ja sam', 'Ја сам', 'I am'],
      ['Hvala', 'Хвала', 'Thank you']
    ];
    expect(wordHintFor('sam', 'Ja sam Kristina.', vocab)?.meaning, 'I am');
    expect(wordHintFor('Хвала!', 'Хвала!', vocab)?.meaning, 'Thank you');
    expect(wordHintFor('i', 'Ana i Kristina', vocab)?.meaning, 'and');
    expect(wordHintFor('unlisted', 'unlisted', vocab), isNull);
  });
}
