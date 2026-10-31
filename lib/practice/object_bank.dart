import '../speech/speech_match.dart';

/// Code-drawn picture keys and the English label shown under each one.
const objectLabels = <String, String>{
  'coffee': 'Coffee',
  'water': 'Water',
  'milk': 'Milk',
  'bread': 'Bread',
  'tea': 'Tea',
  'fruit': 'Fruit',
  'vegetables': 'Vegetables',
  'meat': 'Meat',
  'icecream': 'Ice cream',
  'chocolate': 'Chocolate',
  'salad': 'Salad',
  'soup': 'Soup',
  'eggs': 'Eggs',
  'pasta': 'Pasta',
  'dog': 'Dog',
  'cat': 'Cat',
  'house': 'House',
  'bus': 'Bus',
  'train': 'Train',
  'tram': 'Tram',
  'book': 'Book',
  'school': 'School',
  'menu': 'Menu',
  'phone': 'Phone',
  'sun': 'Sun',
  'rain': 'Rain',
  'jacket': 'Jacket',
  'shoe': 'Shoes',
  'eye': 'Eye',
  'money': 'Money',
};

/// Extra English and Serbian names that should show the picture above.
const objectAliases = <String, String>{
  'sunny': 'sun',
  'rainy': 'rain',
  'coins': 'money',
  'dinar': 'money',
  'kafa': 'coffee',
  'kafu': 'coffee',
  'voda': 'water',
  'vodu': 'water',
  'mleko': 'milk',
  'mlijeko': 'milk',
  'hleb': 'bread',
  'hljeb': 'bread',
  'caj': 'tea',
  'voce': 'fruit',
  'povrce': 'vegetables',
  'meso': 'meat',
  'sladoled': 'icecream',
  'cokolada': 'chocolate',
  'salata': 'salad',
  'supa': 'soup',
  'corba': 'soup',
  'jaje': 'eggs',
  'jaja': 'eggs',
  'testenina': 'pasta',
  'pas': 'dog',
  'psa': 'dog',
  'macka': 'cat',
  'kuca': 'house',
  'kucu': 'house',
  'autobus': 'bus',
  'voz': 'train',
  'tramvaj': 'tram',
  'knjiga': 'book',
  'knjigu': 'book',
  'skola': 'school',
  'skolu': 'school',
  'meni': 'menu',
  'jelovnik': 'menu',
  'telefon': 'phone',
  'sunce': 'sun',
  'suncano': 'sun',
  'kisa': 'rain',
  'kisno': 'rain',
  'jakna': 'jacket',
  'cipele': 'shoe',
  'oko': 'eye',
  'novac': 'money',
  'novca': 'money',
  'dinara': 'money',
};

String? objectKeyFor(String english, String latin) {
  final clean = foldSerbian(english.replaceAll(RegExp(r'\([^)]*\)'), ' '));
  final fromEnglish = _alias(clean);
  if (fromEnglish != null) return fromEnglish;
  final foldedLatin = foldSerbian(latin);
  if (foldedLatin == clean) return null;
  return _alias(foldedLatin);
}

String? _alias(String value) {
  if (value.isEmpty) return null;
  final direct = objectAliases[value];
  if (direct != null) return direct;
  for (final entry in objectLabels.entries) {
    if (foldSerbian(entry.value) == value || entry.key == value) {
      return entry.key;
    }
  }
  return null;
}

class PictureOption {
  final String key, label;
  const PictureOption(this.key, this.label);
  String get encoded => '$key|$label';

  factory PictureOption.parse(String option) {
    if (objectLabels.containsKey(option)) {
      return PictureOption(option, objectLabels[option]!);
    }
    final bar = option.indexOf('|');
    if (bar > 0) {
      final key = option.substring(0, bar);
      final label = option.substring(bar + 1);
      return PictureOption(
          objectLabels.containsKey(key)
              ? key
              : (objectKeyFor(label, key) ?? 'bread'),
          label);
    }
    final parts = option.split(' ');
    final label = parts.length > 1 ? parts.skip(1).join(' ') : option;
    return PictureOption(objectKeyFor(label, '') ?? 'bread', label);
  }
}
