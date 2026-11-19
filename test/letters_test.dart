import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_kristina/main.dart';
import 'package:hello_kristina/feedback/learning_feedback.dart';

Map<String, dynamic> readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final bundled = readJson('assets/course/alphabet.json');

  test('every letter has a name, an example word and both clips', () {
    final list = (bundled['letters'] as List).cast<Map<String, dynamic>>();
    expect(list.length, 30);
    for (var i = 0; i < list.length; i++) {
      final l = list[i];
      final word = (l['word'] as Map).cast<String, dynamic>();
      // Same order and spelling as the built-in alphabet.
      expect(l['cyrillic'], letters[i][0]);
      expect(l['latin'], letters[i][1]);
      expect((l['name'] as String).isNotEmpty, isTrue);
      // The example really starts with its letter, in both scripts.
      expect((word['cyrillic'] as String).toUpperCase(),
          startsWith(l['cyrillic'] as String));
      expect((word['latin'] as String).toLowerCase(),
          startsWith((l['latin'] as String).toLowerCase()));
      for (final clip in [l['nameAudio'], word['audio']]) {
        expect(File('assets/$clip').existsSync(), isTrue,
            reason: '${l['cyrillic']}: $clip');
        expect(File('assets/$clip').lengthSync(), greaterThan(1500));
      }
    }
  });

  test('the bundled alphabet matches its source', () {
    final source =
        (readJson('curriculum/alphabet.json')['letters'] as List).cast<Map>();
    final out = (bundled['letters'] as List).cast<Map>();
    for (var i = 0; i < source.length; i++) {
      for (final key in ['cyrillic', 'latin', 'sound', 'name']) {
        expect(out[i][key], source[i][key]);
      }
      for (final key in ['cyrillic', 'latin', 'english', 'emoji']) {
        expect(out[i]['word'][key], source[i]['word'][key]);
      }
    }
  });

  testWidgets('tapping a letter shows its name and example word',
      (tester) async {
    learningFeedback.sounds = false;
    learningFeedback.vibration = false;
    final previous = alphabet;
    addTearDown(() => alphabet = previous);
    applyAlphabet(bundled);
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LettersPage())));
    await tester.pump();
    expect(find.text('Say it: “а”'), findsOneWidget);
    expect(find.text('avion · aeroplane'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Ж, Ž'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Say it: “же”'), findsOneWidget);
    expect(find.text('žaba · frog'), findsOneWidget);
    expect(find.bySemanticsLabel('Hear žaba, frog'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Hear žaba, frog'));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(tester.takeException(), isNull);
  });
}
