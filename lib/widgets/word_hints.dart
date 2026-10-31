/// Vocabulary-backed hints. Unknown words stay plain instead of guessing.
class WordHint {
  final String term, meaning;
  const WordHint(this.term, this.meaning);
}

String cleanHintWord(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-zа-яђјљњћџčćžšđ0-9\s]'), '')
    .trim();

WordHint? wordHintFor(
    String token, String prompt, List<List<String>> vocabulary) {
  final word = cleanHintWord(token), sentence = ' ${cleanHintWord(prompt)} ';
  if (word.isEmpty) return null;
  if (token == 'i') return const WordHint('i', 'and');
  // Prefer the longest matching phrase from this sentence: e.g. "Ja sam".
  final candidates = <WordHint>[];
  for (final entry in vocabulary) {
    if (entry.length < 3) continue;
    for (var column = 0; column < 3; column++) {
      final phrase = cleanHintWord(entry[column]);
      if (phrase.split(' ').contains(word) && sentence.contains(' $phrase ')) {
        candidates
            .add(WordHint(entry[column], column == 2 ? entry[0] : entry[2]));
      }
    }
  }
  if (candidates.isNotEmpty) {
    candidates.sort((a, b) => b.term.length.compareTo(a.term.length));
    return candidates.first;
  }
  const basics = {
    'ja': 'I',
    'sam': 'am (with I)',
    'ti': 'you (informal)',
    'si': 'are (with ti)',
    'on': 'he',
    'ona': 'she',
    'je': 'is',
    'mi': 'we / to me (depends on the sentence)',
    'vi': 'you (polite or plural)',
    'smo': 'are (with mi)',
    'ste': 'are (with vi)',
    'ovo': 'this',
    'moj': 'my (masculine)',
    'moja': 'my (feminine)',
    'moje': 'my (neuter)',
    'u': 'in / at / into (depends on the sentence)',
    'i': 'and',
    'ne': 'no / not',
    'kafu': 'coffee (object form)',
    'vodu': 'water (object form)',
    'srbiji': 'Serbia (in: u Srbiji)',
    'ću': 'will (with I)',
    'se': 'part of phrases such as zovem se (my name is)',
    'ја': 'I',
    'сам': 'am (with I)',
    'ти': 'you (informal)',
    'си': 'are (with ti)',
    'је': 'is',
    'ово': 'this',
    'и': 'and',
    'не': 'no / not',
  };
  if (basics.containsKey(word)) return WordHint(token, basics[word]!);
  if (['ana', 'kristina', 'miloš', 'zara', 'ана', 'кристина'].contains(word)) {
    return WordHint(token, 'A person’s name. Keep the name when translating.');
  }
  return null;
}
