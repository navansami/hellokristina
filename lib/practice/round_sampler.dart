part of '../main.dart';

/// Build a fresh practice round of 8–12 different challenges.
///
/// Every item keeps a Beta(1 + correct, 1 + wrong) posterior. Thompson
/// sampling draws a mastery probability, turns the miss chance into a weight,
/// and weighted sampling without replacement (Efraimidis–Spirakis) picks the
/// set. A new draw makes the same lesson come out different next time, while
/// recent misses stay more likely to return. The round keeps one or two
/// speaking prompts, and an image choice when the lesson has a drawable word.
List<Question> buildPracticeRound(
        Lesson source, Map<String, List<int>> memory, math.Random random) =>
    selectPracticeRound(practicePool(source), memory, random);

List<Question> selectPracticeRound(List<Question> pool,
    Map<String, List<int>> memory, math.Random random,
    {int minimum = 8, int maximum = 12}) {
  final unique = <String, Question>{};
  for (final question in pool) {
    unique.putIfAbsent(question.id, () => question);
  }
  final items = unique.values.toList();
  if (items.isEmpty) return const [];
  final limit = math.min(maximum, items.length);
  final least = math.min(minimum, limit);
  final count =
      least + (limit == least ? 0 : random.nextInt(limit - least + 1));
  final weights = <String, double>{
    for (final question in items)
      question.id: _practiceWeight(question.id, memory, random),
  };
  final chosen = <String, Question>{};
  void take(Iterable<Question> source, int n) {
    if (n <= 0) return;
    final available = [
      for (final question in source)
        if (!chosen.containsKey(question.id)) question
    ];
    if (available.isEmpty) return;
    for (final question in _weightedSample(
        available, weights, math.min(n, available.length), random)) {
      chosen[question.id] = question;
    }
  }

  final speaks = items.where((question) => question.type == 'Speak the phrase');
  final images = items.where((question) => question.type == 'Choose the image');
  if (speaks.isNotEmpty) {
    final cap = math.min(2, speaks.length);
    take(speaks, 1 + (cap == 1 ? 0 : random.nextInt(cap)));
  }
  if (images.isNotEmpty) {
    final cap = math.min(2, images.length);
    take(images, 1 + (cap == 1 ? 0 : random.nextInt(cap)));
  }
  if (items.any(_authored) &&
      chosen.values.every((question) => !_authored(question))) {
    final speaksTaken =
        chosen.values.where((question) => question.type == 'Speak the phrase').length;
    final imagesTaken =
        chosen.values.where((question) => question.type == 'Choose the image').length;
    take(
        items.where((question) =>
            _authored(question) &&
            (question.type != 'Speak the phrase' || speaksTaken < 2) &&
            (question.type != 'Choose the image' || imagesTaken < 2)),
        1);
  }
  // The quotas above are the whole speaking and picture allowance. Filling
  // from the other formats keeps a 12-item draw from stacking extra images.
  final room = count - chosen.length;
  if (room > 0) {
    take(
        items.where((question) =>
            question.type != 'Speak the phrase' &&
            question.type != 'Choose the image'),
        room);
  }
  final mixed = chosen.values.toList()..shuffle(random);
  return [for (final question in mixed) _shuffleOptions(question, random)];
}

List<Question> practicePool(Lesson source) {
  final pool = <Question>[];
  final seenIds = <String>{};
  final seenSignatures = <String>{};
  void add(Question question) {
    if (question.id.isEmpty) return;
    final signature = '${question.type}|${foldSerbian(question.answer)}';
    if (!seenIds.add(question.id) || !seenSignatures.add(signature)) return;
    pool.add(question);
  }

  for (var i = 0; i < source.questions.length; i++) {
    final question = source.questions[i];
    add(question.copy(
        id: question.id.isEmpty ? '${source.id}:authored:$i' : question.id));
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
        answerLanguage: 'sr'));
    add(Question('Type the answer', 'Write “$english” in Serbian', latin,
        const [], '$latin means $english.',
        id: 'write:${source.id}:$slug',
        audioText: latin,
        audioAsset: audio,
        translation: english,
        answerLanguage: 'sr'));
    add(Question(
        'Translate to Serbian',
        english,
        latin,
        _wordChoices(latin, latins, const [
          'zdravo',
          'hvala',
          'molim',
          'voda',
          'da',
          'ne'
        ]),
        '$english is “$latin”.',
        id: 'say:${source.id}:$slug',
        audioText: latin,
        audioAsset: audio,
        translation: english,
        answerLanguage: 'sr'));
    add(Question(
        'Choose the meaning',
        'What does “$latin” mean?',
        english,
        _wordChoices(english, glosses, const [
          'Hello',
          'Thank you',
          'Please',
          'Water',
          'Yes',
          'Goodbye'
        ]),
        '$latin means $english.',
        id: 'mean:${source.id}:$slug',
        audioText: latin,
        audioAsset: audio,
        translation: english,
        answerLanguage: 'en'));
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
        audioAsset: audio));
  }
  for (var i = 0; i < source.questions.length; i++) {
    final question = source.questions[i];
    final phrase = question.audioText.trim();
    if (!phrase.contains(' ')) continue;
    add(Question(
        'Speak the phrase',
        phrase,
        phrase,
        const [],
        'Say “$phrase”.',
        id: 'speak:${source.id}:line:$i',
        audioText: phrase,
        audioAsset: question.audioAsset,
        translation: question.translation.isNotEmpty
            ? question.translation
            : question.prompt,
        answerLanguage: 'sr'));
  }
  return pool;
}

List<String> _wordChoices(String answer, List<String> bank, List<String> pad) {
  final options = <String>[answer];
  void take(String other) {
    if (options.length == 4) return;
    if (foldSerbian(other) == foldSerbian(answer)) return;
    if (options.any((item) => foldSerbian(item) == foldSerbian(other))) return;
    options.add(other);
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
    String id, Map<String, List<int>> memory, math.Random random) {
  final prior = memory[id];
  final correct = prior == null || prior.isEmpty ? 0 : prior[0];
  final wrong = prior == null || prior.length < 2 ? 0 : prior[1];
  final mastery = sampleBeta((1 + correct).toDouble(), (1 + wrong).toDouble(), random);
  return .08 + (1 - mastery);
}

List<Question> _weightedSample(List<Question> items, Map<String, double> weights,
    int count, math.Random random) {
  final ranked = [
    for (final question in items)
      (
        question: question,
        key: math.pow(
            math.max(random.nextDouble(), 1e-12),
            1 / math.max(weights[question.id] ?? .08, 1e-6))
      )
  ]..sort((a, b) => b.key.compareTo(a.key));
  return ranked.take(count).map((entry) => entry.question).toList();
}

bool _authored(Question question) =>
    !RegExp(r'^(speak|write|say|image|mean):').hasMatch(question.id);

Question _shuffleOptions(Question question, math.Random random) {
  if (question.options.length < 2) return question;
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
