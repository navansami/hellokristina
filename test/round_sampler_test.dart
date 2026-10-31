import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hello_kristina/main.dart';
import 'package:hello_kristina/practice/object_bank.dart';
import 'package:hello_kristina/speech/speech_match.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final catalog =
      jsonDecode(File('curriculum/serbian-en.v1.json').readAsStringSync())
          as Map<String, dynamic>;
  final lessons = [
    for (final unit in catalog['units'] as List)
      for (final raw in unit['lessons'] as List)
        _lesson(raw as Map<String, dynamic>)
  ];

  test('speech folding accepts Latin, Cyrillic and small recognition slips',
      () {
    expect(speechMatches('Zdravo!', 'zdravo'), isTrue);
    expect(speechMatches('Здраво', 'Zdravo'), isTrue);
    expect(speechMatches('caj', 'čaj'), isTrue);
    expect(speechMatches('Kafu, molim.', 'Kafu molim'), isTrue);
    expect(speechMatches('ne', 'da'), isFalse);
    expect(speechMatches('goodbye', 'zdravo'), isFalse);
    expect(PictureOption.parse('☕ Coffee').key, 'coffee');
    expect(PictureOption.parse('water|Water').label, 'Water');
    expect(objectKeyFor('coffee (object)', 'kafa'), 'coffee');
    expect(objectKeyFor('Please', 'molim'), isNull);
  });

  test('every lesson can deal a fresh round of 8 to 12 different challenges',
      () {
    for (final lesson in lessons) {
      final pool = practicePool(lesson);
      expect(pool.length, greaterThanOrEqualTo(12), reason: lesson.id);
      expect(pool.map((question) => question.id).toSet().length, pool.length,
          reason: lesson.id);
      final pictures =
          pool.where((question) => question.type == 'Choose the image');
      final signatures = <String>{};
      for (var seed = 1; seed <= 8; seed++) {
        final round =
            buildPracticeRound(lesson, const {}, Random(seed)).questions;
        expect(round.length, inInclusiveRange(8, 12),
            reason: '${lesson.id} #$seed');
        expect(round.map((question) => question.id).toSet().length, round.length,
            reason: lesson.id);
        expect(
            round
                .map((question) =>
                    '${question.type}|${foldSerbian(question.answer)}')
                .toSet()
                .length,
            round.length,
            reason: lesson.id);
        expect(
            round.where((question) => question.type == 'Speak the phrase').length,
            inInclusiveRange(1, 2),
            reason: lesson.id);
        if (pictures.isNotEmpty) {
          expect(
              round
                  .where((question) => question.type == 'Choose the image')
                  .length,
              inInclusiveRange(1, 2),
              reason: lesson.id);
        }
        expect(
            round.any((question) =>
                question.type == 'Type the answer' ||
                question.type == 'Listen and type' ||
                question.type == 'Choose the meaning' ||
                question.type == 'Translate to Serbian'),
            isFalse,
            reason: lesson.id);
        expect(
            round.where((question) =>
                !question.id.startsWith('speak:') &&
                !question.id.startsWith('write:') &&
                !question.id.startsWith('say:') &&
                !question.id.startsWith('image:') &&
                !question.id.startsWith('mean:') &&
                !question.id.startsWith('tiles:') &&
                !question.id.startsWith('hear:')),
            isNotEmpty,
            reason: lesson.id);
        for (final question in round) {
          if (question.type == 'Arrange the words' ||
              question.type == 'Listen and arrange') {
            final tokens = List<String>.from(question.options);
            for (final word in question.answer.split(' ')) {
              final at = tokens.indexOf(word);
              expect(at, greaterThanOrEqualTo(0), reason: question.id);
              tokens.removeAt(at);
            }
          } else if (question.options.isNotEmpty) {
            expect(question.options, contains(question.answer),
                reason: question.id);
          }
        }
        signatures.add(round.map((question) => question.id).join('|'));
      }
      expect(signatures.length, greaterThan(1), reason: lesson.id);
      final before = lesson.questions.map((question) => question.options.join('|')).join('||');
      buildPracticeRound(lesson, const {}, Random(4));
      expect(
          lesson.questions.map((question) => question.options.join('|')).join('||'),
          before,
          reason: lesson.id);
    }
  });

  test('the same draw is reproducible and a weak item returns more often', () {
    final pool = [
      for (var i = 0; i < 16; i++)
        Question('Type the answer', 'Write $i', 'word$i', const [], 'Because.',
            id: 'item-$i')
    ];
    final first = selectPracticeRound(pool, const {}, Random(7))
        .map((question) => question.id)
        .join('|');
    final again = selectPracticeRound(pool, const {}, Random(7))
        .map((question) => question.id)
        .join('|');
    expect(again, first);
    const memory = {
      'item-0': [0, 12],
      'item-1': [12, 0],
    };
    var weak = 0, strong = 0;
    for (var seed = 0; seed < 160; seed++) {
      final round = selectPracticeRound(pool, memory, Random(seed));
      if (round.any((question) => question.id == 'item-0')) weak++;
      if (round.any((question) => question.id == 'item-1')) strong++;
    }
    expect(weak, greaterThan(strong));
  });

  test('answered challenges update the saved Beta counts', () async {
    SharedPreferences.setMockInitialValues({});
    final question = Question('Speak the phrase', 'Zdravo', 'Zdravo', const [],
        'Say hello.',
        id: 'speak:hello:zdravo');
    await PracticeMemory.record([question], [false]);
    await PracticeMemory.record([question], [true]);
    final memory = await PracticeMemory.load();
    expect(memory['speak:hello:zdravo'], [1, 1]);
  });
}

Lesson _lesson(Map<String, dynamic> data) {
  final vocabulary = (data['vocabulary'] as List).map((raw) {
    final entry = raw as Map<String, dynamic>;
    return <String>[
      entry['latin'],
      entry['cyrillic'],
      entry['english'],
      entry['pronunciation'],
      entry['audio'] ?? '',
    ];
  }).toList();
  final questions = (data['challenges'] as List).map((raw) {
    final item = raw as Map<String, dynamic>;
    return Question(
        item['type'],
        item['prompt'],
        item['answer'],
        (item['options'] as List).cast<String>(),
        item['explanation'],
        id: item['id'],
        audioText: item['audioText'] ?? '',
        audioAsset: item['audio'] ?? '',
        translation: item['translation'] ?? '',
        answerLanguage: item['answerLanguage'] ?? '');
  }).toList();
  return Lesson(data['id'], data['title'], data['subtitle'], data['icon'],
      data['color'], questions,
      kind: data['type'] ?? 'challenge',
      minPassPercent: data['minPassPercent'] ?? 0,
      vocabulary: vocabulary);
}
