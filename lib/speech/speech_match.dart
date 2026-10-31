import 'dart:math' as math;

const _cyrillic = {
  'а': 'a',
  'б': 'b',
  'в': 'v',
  'г': 'g',
  'д': 'd',
  'ђ': 'dj',
  'е': 'e',
  'ж': 'z',
  'з': 'z',
  'и': 'i',
  'ј': 'j',
  'к': 'k',
  'л': 'l',
  'љ': 'lj',
  'м': 'm',
  'н': 'n',
  'њ': 'nj',
  'о': 'o',
  'п': 'p',
  'р': 'r',
  'с': 's',
  'т': 't',
  'ћ': 'c',
  'у': 'u',
  'ф': 'f',
  'х': 'h',
  'ц': 'c',
  'ч': 'c',
  'џ': 'dz',
  'ш': 's',
};

/// Fold Serbian Latin and Cyrillic into comparable ASCII.
String foldSerbian(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_cyrillic[char] ?? char);
  }
  final text = buffer
      .toString()
      .replaceAll('đ', 'dj')
      .replaceAll('č', 'c')
      .replaceAll('ć', 'c')
      .replaceAll('š', 's')
      .replaceAll('ž', 'z')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
  return text;
}

/// Lenient match for a browser or device transcript of a Serbian phrase.
bool speechMatches(String heard, String target) {
  final left = foldSerbian(heard);
  final right = foldSerbian(target);
  if (left.isEmpty || right.isEmpty) return false;
  if (left == right) return true;
  if (right.length >= 4 &&
      left.contains(right) &&
      left.length <= right.length + 6) {
    return true;
  }
  final limit = right.length <= 5 ? 1 : math.max(1, (right.length / 8).ceil());
  return _editDistance(left, right) <= limit;
}

int _editDistance(String left, String right) {
  if (left == right) return 0;
  if (left.isEmpty) return right.length;
  if (right.isEmpty) return left.length;
  var previous = List<int>.generate(right.length + 1, (index) => index);
  for (var i = 0; i < left.length; i++) {
    final current = List<int>.filled(right.length + 1, 0);
    current[0] = i + 1;
    for (var j = 0; j < right.length; j++) {
      final cost = left.codeUnitAt(i) == right.codeUnitAt(j) ? 0 : 1;
      current[j + 1] = math.min(
          math.min(current[j] + 1, previous[j + 1] + 1), previous[j] + cost);
    }
    previous = current;
  }
  return previous.last;
}
