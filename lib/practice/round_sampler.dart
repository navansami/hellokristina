part of '../main.dart';

/// Build a short, adaptive practice session.
///
/// Every item keeps a Beta(1 + correct, 1 + wrong) posterior. Thompson
/// sampling draws a mastery probability, turns the miss chance into a weight,
/// and weighted sampling without replacement (Efraimidis–Spirakis) picks the
/// set. Items seen in the last session or two are damped so back-to-back
/// sessions differ. A session uses each word at most twice, keeps one or two
/// speaking prompts, at most one picture and one pairs game, and mixes in
/// weak items from [review] lessons. Length adapts to how well the lesson's
/// items are known (see [adaptiveSessionLength]); misses add retries during
/// the lesson (see `LessonPage`). Checkpoints deal 10 and the final assessment
/// 12, with no review and no retries. [PracticeDeal.bench] holds spare
/// non-speaking questions for microphone skips and retries.
PracticeDeal buildPracticeRound(
    Lesson source, Map<String, List<int>> memory, math.Random random,
    {List<Lesson> review = const [], int session = 0}) {
  final pool = practicePool(source);
  final graded = source.kind != 'challenge';
  final count = graded
      ? (source.kind == 'assessment' ? 12 : 10)
      : adaptiveSessionLength(pool, memory);
  final reviewPool = graded
      ? const <Question>[]
      : [
          for (final lesson in review)
            for (final question in practicePool(lesson))
              if (question.type != 'Speak the phrase' &&
                  question.type != 'Match the pairs')
                question.copy(review: true)
        ];
  final questions = selectPracticeRound(pool, memory, random,
      count: count,
      session: session,
      review: reviewPool,
      reviewCount: reviewPool.isEmpty ? 0 : (count >= 7 ? 2 : 1));
  final used = {for (final question in questions) question.id};
  final bench = [
    for (final question in pool)
      if (!used.contains(question.id) &&
          question.type != 'Speak the phrase' &&
          question.type != 'Match the pairs' &&
          question.type != 'Type the answer' &&
          question.type != 'Listen and type')
        question
  ]..shuffle(random);
  return PracticeDeal(questions, bench);
}

class PracticeDeal {
  final List<Question> questions;
  final List<Question> bench;
  const PracticeDeal(this.questions, this.bench);
}

/// 7 for a new lesson, 5 when its items are well known, 6 when mostly known,
/// and 8 when the learner is struggling.
int adaptiveSessionLength(List<Question> pool, Map<String, List<int>> memory) {
  var seen = 0;
  var mastery = 0.0;
  for (final question in pool) {
    final prior = memory[question.id];
    if (prior == null || prior.length < 2) continue;
    seen++;
    mastery += (1 + prior[0]) / (2 + prior[0] + prior[1]);
  }
  if (seen < 3) return 7;
  final mean = mastery / seen;
  if (mean >= .8) return 5;
  if (mean >= .65) return 6;
  if (mean >= .5) return 7;
  return 8;
}

List<Question> selectPracticeRound(
    List<Question> pool, Map<String, List<int>> memory, math.Random random,
    {int minimum = 8,
    int maximum = 12,
    int? count,
    int session = 0,
    List<Question> review = const [],
    int reviewCount = 0}) {
  final unique = <String, Question>{};
  for (final question in pool) {
    unique.putIfAbsent(question.id, () => question);
  }
  final items = unique.values.toList();
  if (items.isEmpty) return const [];
  final int size;
  if (count != null) {
    size = math.min(count, items.length + reviewCount);
  } else {
    final limit = math.min(maximum, items.length);
    final least = math.min(minimum, limit);
    size = least + (limit == least ? 0 : random.nextInt(limit - least + 1));
  }
  final weights = <String, double>{
    for (final question in [...items, ...review])
      question.id: _practiceWeight(question.id, memory, random, session),
  };
  final chosen = <String, Question>{};
  final perFocus = <String, int>{};
  bool fits(Question question) =>
      !chosen.containsKey(question.id) &&
      (question.focus.isEmpty || (perFocus[question.focus] ?? 0) < 2);
  void take(Iterable<Question> source, int n) {
    for (var picked = 0; picked < n; picked++) {
      final available = [
        for (final question in source)
          if (fits(question)) question
      ];
      if (available.isEmpty) return;
      // One at a time so the per-word cap applies to every pick.
      final question = _weightedSample(available, weights, 1, random).first;
      chosen[question.id] = question;
      if (question.focus.isNotEmpty) {
        perFocus[question.focus] = (perFocus[question.focus] ?? 0) + 1;
      }
    }
  }

  bool special(Question question) =>
      question.type == 'Speak the phrase' ||
      question.type == 'Choose the image' ||
      question.type == 'Match the pairs';
  final speaks = items.where((question) => question.type == 'Speak the phrase');
  final images = items.where((question) => question.type == 'Choose the image');
  final pairs = items.where((question) => question.type == 'Match the pairs');
  // Hand-written sentences, dialogues and readings carry the lesson, so they
  // fill about two in five places; word drills fill the rest. At most one
  // reading per session, because readings take longer.
  int readings() => chosen.values
      .where((question) => question.type == 'Read and answer')
      .length;
  final authoredTarget = math.max(1, (size * .4).round());
  for (var k = 0; k < authoredTarget; k++) {
    take(
        items.where((question) =>
            _authored(question) &&
            !special(question) &&
            (question.type != 'Read and answer' || readings() == 0)),
        1);
  }
  if (speaks.isNotEmpty) {
    final cap = math.min(size >= 8 ? 2 : 1, speaks.length);
    take(speaks, 1 + (cap == 1 ? 0 : random.nextInt(cap)));
  }
  if (images.isNotEmpty) take(images, 1);
  if (pairs.isNotEmpty && size >= 5) take(pairs, 1);
  if (reviewCount > 0) {
    final own = {for (final question in items) question.id};
    take(review.where((question) => !own.contains(question.id)), reviewCount);
  }
  // The quotas above are the whole speaking, picture and pairs allowance.
  // Listening picks stay at two so the session keeps its variety.
  int picks() => chosen.values
      .where((question) => question.type == 'Listen and choose')
      .length;
  for (var room = size - chosen.length; room > 0; room--) {
    final before = chosen.length;
    take(
        items.where((question) =>
            !special(question) &&
            (question.type != 'Read and answer' || readings() == 0) &&
            (question.type != 'Listen and choose' || picks() < 2)),
        1);
    if (chosen.length == before) break;
  }
  // A tiny lesson makes a shorter session rather than repeating its words.
  // The cap relaxes only as far as the five-answer minimum.
  if (chosen.length < math.min(5, size)) {
    perFocus.clear();
    take(items.where((question) => !special(question)),
        math.min(5, size) - chosen.length);
  }
  final mixed = _spreadTypes(chosen.values.toList()..shuffle(random));
  return [for (final question in mixed) _shuffleOptions(question, random)];
}

/// Reorder so the same exercise format rarely appears twice in a row and
/// a session never opens with speaking.
List<Question> _spreadTypes(List<Question> questions) {
  final rest = [...questions];
  final ordered = <Question>[];
  while (rest.isNotEmpty) {
    final last = ordered.isEmpty ? 'Speak the phrase' : ordered.last.type;
    final at = rest.indexWhere((question) => question.type != last);
    ordered.add(rest.removeAt(at < 0 ? 0 : at));
  }
  return ordered;
}

List<Question> practicePool(Lesson source) {
  final pool = <Question>[];
  final seenIds = <String>{};
  final seenSignatures = <String>{};
  void add(Question question) {
    if (question.id.isEmpty) return;
    final signature = '${question.type}|${foldSerbian(question.answer)}';
    if (question.type != 'Match the pairs' &&
        (!seenIds.add(question.id) || !seenSignatures.add(signature))) {
      return;
    }
    if (question.type == 'Match the pairs' && !seenIds.add(question.id)) return;
    pool.add(question);
  }

  for (var i = 0; i < source.questions.length; i++) {
    final question = source.questions[i];
    if (question.type == 'Type the answer' ||
        question.type == 'Listen and type' ||
        question.type == 'Choose the meaning' ||
        question.type == 'Translate to Serbian') {
      continue;
    }
    add(question.copy(
        id: question.id.isEmpty ? '${source.id}:authored:$i' : question.id,
        focus: _focusFor(question, source.vocabulary)));
  }
  final rows = source.vocabulary
      .where((row) => row.isNotEmpty && row.first.trim().isNotEmpty)
      .toList();
  final latins = rows.map((row) => row.first.trim()).toList();
  final glosses = rows
      .map((row) => row.length > 2 ? row[2].trim() : row.first.trim())
      .toList();
  for (final row in rows) {
    final latin = row.first.trim();
    final english = row.length > 2 ? row[2].trim() : latin;
    final audio = row.length > 4 ? row[4] : '';
    final slug = _slug(latin);
    add(Question(
        'Speak the phrase', latin, latin, const [], 'Say “$latin” — $english.',
        id: 'speak:${source.id}:$slug',
        audioText: latin,
        audioAsset: audio,
        translation: english,
        answerLanguage: 'sr',
        focus: slug));
    final serbian = _plain(latin);
    final meaning = _plain(english);
    if (serbian.isNotEmpty) {
      add(Question(
          'Arrange the words',
          english,
          serbian,
          _tileOptions(serbian, latins,
              const ['zdravo', 'hvala', 'molim', 'voda', 'da', 'ne']),
          '$english is “$latin”.',
          id: 'say:${source.id}:$slug',
          audioText: latin,
          audioAsset: audio,
          answerLanguage: 'sr',
          focus: slug));
    }
    if (meaning.isNotEmpty && foldSerbian(meaning) != foldSerbian(serbian)) {
      final meaningTiles = _tileOptions(meaning, glosses,
          const ['Hello', 'Thank you', 'Please', 'Yes', 'Water', 'Goodbye']);
      add(Question('Arrange the words', latin, meaning, meaningTiles,
          '$latin means $english.',
          id: 'tiles:${source.id}:$slug',
          audioText: latin,
          audioAsset: audio,
          answerLanguage: 'en',
          focus: slug));
      add(Question('Listen and arrange', 'Listen and build the translation.',
          meaning, List<String>.from(meaningTiles), '$latin means $english.',
          id: 'hear:${source.id}:$slug',
          audioText: latin,
          audioAsset: audio,
          answerLanguage: 'en',
          focus: slug));
    }
    // Hear a word and pick it from other Serbian words in the lesson.
    final others = [
      for (final other in latins)
        if (_plain(other).isNotEmpty &&
            foldSerbian(_plain(other)) != foldSerbian(serbian))
          _plain(other)
    ];
    if (serbian.isNotEmpty && others.length >= 2) {
      final start = slug.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
      final picks = <String>[];
      for (var k = 0; k < others.length && picks.length < 2; k++) {
        final candidate = others[(start + k) % others.length];
        if (!picks.any((item) => foldSerbian(item) == foldSerbian(candidate))) {
          picks.add(candidate);
        }
      }
      if (picks.length == 2) {
        add(Question('Listen and choose', 'Listen and choose', serbian,
            [serbian, ...picks], '$latin means $english.',
            id: 'pick:${source.id}:$slug',
            audioText: latin,
            audioAsset: audio,
            focus: slug));
      }
    }
    final key = objectKeyFor(english, latin);
    if (key == null) continue;
    final label = objectLabels[key] ?? key;
    final distractors = objectLabels.keys.where((item) => item != key).toList();
    if (distractors.length < 3) continue;
    final start = key.codeUnits.fold<int>(0, (sum, unit) => sum + unit) %
        distractors.length;
    final wrong = List.generate(
        3, (index) => distractors[(start + index) % distractors.length]);
    final answer = '$key|$label';
    add(Question(
        'Choose the image',
        'Which one is “$latin”?',
        answer,
        [
          answer,
          for (final item in wrong) '$item|${objectLabels[item]}',
        ],
        '$latin means $label.',
        id: 'image:${source.id}:$key',
        audioText: latin,
        audioAsset: audio,
        focus: slug));
  }
  // A quick pairs game over up to five short words.
  final pairs = <String>[];
  final seenLatin = <String>{}, seenEnglish = <String>{};
  for (final row in rows) {
    final latin = _plain(row.first);
    final english = _plain(row.length > 2 ? row[2] : '');
    if (latin.isEmpty || english.isEmpty) continue;
    if (latin.length > 20 || english.length > 20) continue;
    if (!seenLatin.add(foldSerbian(latin)) ||
        !seenEnglish.add(english.toLowerCase())) {
      continue;
    }
    pairs.add('$latin|$english');
    if (pairs.length == 5) break;
  }
  if (pairs.length >= 4) {
    add(Question('Match the pairs', 'Tap the matching pairs', '', pairs,
        'Match each Serbian word with its meaning.',
        id: 'pairs:${source.id}', answerLanguage: 'sr'));
  }
  for (var i = 0; i < source.questions.length; i++) {
    final question = source.questions[i];
    final phrase = question.audioText.trim();
    if (!phrase.contains(' ')) continue;
    add(Question('Speak the phrase', phrase, phrase, const [], 'Say “$phrase”.',
        id: 'speak:${source.id}:line:$i',
        audioText: phrase,
        audioAsset: question.audioAsset,
        translation: question.translation.isNotEmpty
            ? question.translation
            : question.prompt,
        answerLanguage: 'sr',
        focus: _focusFor(question, source.vocabulary)));
  }
  return pool;
}

String _plain(String value) => value
    .replaceAll(RegExp(r'[.,!?;:“”"]'), '')
    .trim()
    .replaceAll(RegExp(r'\s+'), ' ');

/// Answer words plus up to three distractor words. The answer tokens stay
/// exact so the joined tile order matches the answer.
List<String> _tileOptions(String answer, List<String> bank, List<String> pad) {
  final correct =
      _plain(answer).split(' ').where((word) => word.isNotEmpty).toList();
  final options = [...correct];
  void take(String raw) {
    for (final piece in _plain(raw).split(' ')) {
      if (piece.isEmpty || options.length >= correct.length + 3) return;
      if (options.any((item) => foldSerbian(item) == foldSerbian(piece))) {
        continue;
      }
      options.add(piece);
    }
  }

  for (final other in bank) {
    take(other);
  }
  for (final other in pad) {
    take(other);
  }
  return options;
}

double sampleBeta(double alpha, double beta, math.Random random) {
  final left = _sampleGamma(alpha, random);
  final right = _sampleGamma(beta, random);
  final total = left + right;
  if (total == 0) return .5;
  return left / total;
}

double _practiceWeight(
    String id, Map<String, List<int>> memory, math.Random random, int session) {
  final prior = memory[id];
  final correct = prior == null || prior.isEmpty ? 0 : prior[0];
  final wrong = prior == null || prior.length < 2 ? 0 : prior[1];
  final mastery =
      sampleBeta((1 + correct).toDouble(), (1 + wrong).toDouble(), random);
  // Damp items from the last two sessions so consecutive sessions differ.
  var recency = 1.0;
  if (prior != null && prior.length > 2 && session > 0) {
    final gap = session - prior[2];
    recency = gap <= 0
        ? .2
        : gap == 1
            ? .55
            : 1.0;
  }
  return (.08 + (1 - mastery)) * recency;
}

/// The lesson word an authored exercise practises: the longest vocabulary
/// entry found in its answer, audio or prompt.
String _focusFor(Question question, List<List<String>> vocabulary) {
  final text =
      ' ${foldSerbian(_plain('${question.answer} ${question.audioText} ${question.prompt}'))} ';
  var best = '';
  for (final row in vocabulary) {
    if (row.isEmpty) continue;
    final word = foldSerbian(_plain(row.first));
    if (word.isEmpty || !text.contains(' $word ')) continue;
    if (word.length > best.length) best = word;
  }
  return best.replaceAll(' ', '-');
}

List<Question> _weightedSample(List<Question> items,
    Map<String, double> weights, int count, math.Random random) {
  final ranked = [
    for (final question in items)
      (
        question: question,
        key: math.pow(math.max(random.nextDouble(), 1e-12),
            1 / math.max(weights[question.id] ?? .08, 1e-6))
      )
  ]..sort((a, b) => b.key.compareTo(a.key));
  return ranked.take(count).map((entry) => entry.question).toList();
}

bool _authored(Question question) =>
    !RegExp(r'^(speak|write|say|image|mean|tiles|hear|pick|pairs|retry|swap):')
        .hasMatch(question.id);

Question _shuffleOptions(Question question, math.Random random) {
  if (question.options.length < 2 || question.type == 'Match the pairs') {
    return question;
  }
  final options = List<String>.from(question.options)..shuffle(random);
  return question.copy(options: options);
}

double _sampleGamma(double shape, math.Random random) {
  if (shape < 1) {
    final unit = math.max(random.nextDouble(), 1e-12);
    return _sampleGamma(shape + 1, random) * math.pow(unit, 1 / shape);
  }
  final d = shape - 1 / 3;
  final c = 1 / math.sqrt(9 * d);
  for (var attempt = 0; attempt < 10000; attempt++) {
    var x = 0.0;
    var v = 0.0;
    do {
      x = _standardNormal(random);
      v = 1 + c * x;
    } while (v <= 0);
    v = v * v * v;
    final unit = random.nextDouble();
    final square = x * x;
    if (unit < 1 - 0.0331 * square * square) return d * v;
    if (v > 0 && math.log(unit) < 0.5 * square + d * (1 - v + math.log(v))) {
      return d * v;
    }
  }
  return shape;
}

double _standardNormal(math.Random random) {
  final unit = math.max(random.nextDouble(), 1e-12);
  final angle = random.nextDouble();
  return math.sqrt(-2 * math.log(unit)) * math.cos(2 * math.pi * angle);
}

String _slug(String value) => foldSerbian(value).replaceAll(' ', '-');
