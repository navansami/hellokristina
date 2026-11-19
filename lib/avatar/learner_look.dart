import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A learner's avatar, assembled from pieces that all mix and match.
///
/// Every field is an index into a style list or a palette. The colour
/// palettes keep the first-generation colours first, so old saved looks
/// (see [LearnerLook.decode]) keep their colours exactly.
/// `server/avatar.js` lists the same ranges; a test checks they agree.
class LearnerLook {
  // Face
  final int skin, face, cheeks;
  // Eyes
  final int eyes, eyeColor, brows;
  // Mouth
  final int mouth;
  // Hair
  final int hair, hairColor, facialHair;
  // Extras
  final int glasses, glassesColor, earrings;
  // Headwear
  final int hat, hatColor;
  // Outfit
  final int outfit, outfitColor, pattern;
  // Background
  final int background, backdrop;

  const LearnerLook({
    this.skin = 6,
    this.face = 0,
    this.cheeks = 1,
    this.eyes = 0,
    this.eyeColor = 0,
    this.brows = 1,
    this.mouth = 0,
    this.hair = 2,
    this.hairColor = 1,
    this.facialHair = 0,
    this.glasses = 0,
    this.glassesColor = 1,
    this.earrings = 0,
    this.hat = 0,
    this.hatColor = 1,
    this.outfit = 0,
    this.outfitColor = 4,
    this.pattern = 0,
    this.background = 0,
    this.backdrop = 1,
  });

  // ---- Palettes ----------------------------------------------------------

  static const skins = [
    Color(0xFF4A2C24), Color(0xFF5C382C), Color(0xFF6B4334), //
    Color(0xFF7A4E3A), Color(0xFF8A5A42), Color(0xFF9A684C),
    Color(0xFFA87456), Color(0xFFB88362), Color(0xFFC49270),
    Color(0xFFD0A27E), Color(0xFFDBB08C), Color(0xFFE4BE9C),
    Color(0xFFECCAAC), Color(0xFFF3D6BC), Color(0xFFF8E0CC),
    Color(0xFFFDEADB),
    // Just for fun.
    Color(0xFFC9B8F2), Color(0xFFA8E6CF), Color(0xFFA9D4F5),
    Color(0xFFF8B9D4),
  ];
  static const eyeColors = [
    Color(0xFF3A2C24), Color(0xFFC2652A), Color(0xFFC6A23A), //
    Color(0xFF3E8C48), Color(0xFF3A8C8A), Color(0xFF3F7AD6),
    Color(0xFF6E7A88), Color(0xFF8A55D0),
  ];
  static const hairColors = [
    Color(0xFF2A241F), Color(0xFF4A3428), Color(0xFF6E302C), //
    Color(0xFF7A4E32), Color(0xFF8E4034), Color(0xFFC6A15A),
    Color(0xFFE07B39), Color(0xFFF2D27A), Color(0xFFEDE6DA),
    Color(0xFF9A9AA6), Color(0xFFF27BB0), Color(0xFF9B6BF2),
    Color(0xFF3D8BF2), Color(0xFF2DBFA6), Color(0xFFE5484D),
    Color(0xFF1F2A4A),
  ];
  static const glassesColors = [
    Color(0xFF8B6AD6), Color(0xFF3C7DDB), Color(0xFF3E9A55), //
    Color(0xFFE08A2E), Color(0xFFD64545), Color(0xFF221C3F),
    Color(0xFFE9B949), Color(0xFFF27BB0), Color(0xFF2DBFA6),
    Color(0xFFF4F4F4),
  ];
  static const hatColors = [
    Color(0xFF8B6AD6), Color(0xFF3C7DDB), Color(0xFF3E9A55), //
    Color(0xFFF2D34A), Color(0xFFE08A2E), Color(0xFFD64545),
    Color(0xFFF27BB0), Color(0xFF2DBFA6), Color(0xFF221C3F),
    Color(0xFFF4F4F4), Color(0xFF7C6A55), Color(0xFF5E6B3A),
  ];
  static const outfitColors = [
    Color(0xFFB07CDB), Color(0xFF4AA3E8), Color(0xFF5EBE6A), //
    Color(0xFFF2D34A), Color(0xFFF0A04A), Color(0xFFD4536A),
    Color(0xFFF2B4C8), Color(0xFFF4F4F4), Color(0xFF4E555C),
    Color(0xFF2DBFA6), Color(0xFF3B4FB8), Color(0xFFE5484D),
    Color(0xFF8A5A3C), Color(0xFF9DD36A), Color(0xFF221C3F),
    Color(0xFFFF8A65),
  ];
  static const backgrounds = [
    Color(0xFFF6E7A8), Color(0xFFE7E7E7), Color(0xFF8D8D8D), //
    Color(0xFF5C5C5C), Color(0xFFF3D6E4), Color(0xFFE4D4F5),
    Color(0xFFC9B6F2), Color(0xFFB7D9F8), Color(0xFF9FD4F5),
    Color(0xFF6AA8D8), Color(0xFF2F6FA8), Color(0xFFD5F3EA),
    Color(0xFFB7E6D4), Color(0xFF8FD6B8), Color(0xFF6FCB7A),
    Color(0xFFB7D96A), Color(0xFFF3D56A), Color(0xFFF6C27A),
    Color(0xFFF3B4C4), Color(0xFFE8A0B8),
  ];

  // ---- Style names (also the option counts) -------------------------------

  static const faceShapes = ['Round', 'Oval', 'Heart', 'Square'];
  static const cheekStyles = [
    'None', 'Rosy', 'Freckles', 'Rosy freckles', 'Hearts', 'Stars', //
    'Plaster',
  ];
  static const eyeStyles = [
    'Bright', 'Sparkly', 'Happy', 'Sleepy', 'Wink', 'Starry', 'Hearts', //
    'Dots', 'Lashes',
  ];
  static const browStyles = [
    'None', 'Soft', 'Bold', 'Raised', 'Fierce', 'Worried', //
  ];
  static const mouthStyles = [
    'Smile', 'Grin', 'Laugh', 'Smirk', 'Cheeky', 'Kitty', 'Wow', 'Calm', //
  ];
  static const hairStyles = [
    'Bald', 'Buzz', 'Crop', 'Side part', 'Quiff', 'Curls', 'Afro', //
    'Top bun', 'Space buns', 'Ponytail', 'Pigtails', 'Bob', 'Long', 'Waves',
    'Braids', 'Mohawk', 'Spiky', 'Curtains', 'Mullet', 'Pixie',
  ];
  static const facialHairStyles = [
    'None', 'Stubble', 'Moustache', 'Beard', 'Goatee', //
  ];
  static const glassesStyles = [
    'None', 'Round', 'Square', 'Cat-eye', 'Shades', 'Star shades', //
    'Heart shades', 'Nerdy',
  ];
  static const earringStyles = ['None', 'Studs', 'Hoops'];
  static const hatStyles = [
    'None', 'Beanie', 'Cap', 'Backwards', 'Bucket', 'Beret', 'Šajkača', //
    'Crown', 'Flowers', 'Headphones', 'Bow', 'Headband', 'Party', 'Cat ears',
    'Bunny ears', 'Wizard',
  ];
  static const outfitStyles = [
    'T-shirt', 'Hoodie', 'Sweater', 'Collar', 'Dungarees', 'Jacket', //
    'Tank top', 'Turtleneck', 'Folk vest',
  ];
  static const patterns = [
    'Plain', 'Stripes', 'Dots', 'Stars', 'Hearts', 'Zigzag', //
  ];
  static const backdrops = [
    'Plain', 'Dots', 'Stars', 'Sunburst', 'Hearts', 'Waves', 'Confetti', //
    'City',
  ];

  /// How many options each field has, in saving order.
  static final Map<String, int> ranges = {
    'skin': skins.length,
    'face': faceShapes.length,
    'cheeks': cheekStyles.length,
    'eyes': eyeStyles.length,
    'eyeColor': eyeColors.length,
    'brows': browStyles.length,
    'mouth': mouthStyles.length,
    'hair': hairStyles.length,
    'hairColor': hairColors.length,
    'facialHair': facialHairStyles.length,
    'glasses': glassesStyles.length,
    'glassesColor': glassesColors.length,
    'earrings': earringStyles.length,
    'hat': hatStyles.length,
    'hatColor': hatColors.length,
    'outfit': outfitStyles.length,
    'outfitColor': outfitColors.length,
    'pattern': patterns.length,
    'background': backgrounds.length,
    'backdrop': backdrops.length,
  };

  Color get skinColor => skins[skin];
  Color get eyeColorValue => eyeColors[eyeColor];
  Color get hairColorValue => hairColors[hairColor];
  Color get glassesColorValue => glassesColors[glassesColor];
  Color get hatColorValue => hatColors[hatColor];
  Color get outfitColorValue => outfitColors[outfitColor];
  Color get backgroundColor => backgrounds[background];

  String get backgroundHex {
    final hex = backgroundColor
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2);
    return '#${hex.toUpperCase()}';
  }

  Map<String, int> toJson() => {
        'skin': skin,
        'face': face,
        'cheeks': cheeks,
        'eyes': eyes,
        'eyeColor': eyeColor,
        'brows': brows,
        'mouth': mouth,
        'hair': hair,
        'hairColor': hairColor,
        'facialHair': facialHair,
        'glasses': glasses,
        'glassesColor': glassesColor,
        'earrings': earrings,
        'hat': hat,
        'hatColor': hatColor,
        'outfit': outfit,
        'outfitColor': outfitColor,
        'pattern': pattern,
        'background': background,
        'backdrop': backdrop,
      };

  LearnerLook withValue(String key, int value) {
    final map = toJson()..[key] = value;
    return LearnerLook._fromMap(map);
  }

  int valueOf(String key) => toJson()[key]!;

  LearnerLook copyWith({
    int? skin,
    int? face,
    int? cheeks,
    int? eyes,
    int? eyeColor,
    int? brows,
    int? mouth,
    int? hair,
    int? hairColor,
    int? facialHair,
    int? glasses,
    int? glassesColor,
    int? earrings,
    int? hat,
    int? hatColor,
    int? outfit,
    int? outfitColor,
    int? pattern,
    int? background,
    int? backdrop,
  }) =>
      LearnerLook(
        skin: skin ?? this.skin,
        face: face ?? this.face,
        cheeks: cheeks ?? this.cheeks,
        eyes: eyes ?? this.eyes,
        eyeColor: eyeColor ?? this.eyeColor,
        brows: brows ?? this.brows,
        mouth: mouth ?? this.mouth,
        hair: hair ?? this.hair,
        hairColor: hairColor ?? this.hairColor,
        facialHair: facialHair ?? this.facialHair,
        glasses: glasses ?? this.glasses,
        glassesColor: glassesColor ?? this.glassesColor,
        earrings: earrings ?? this.earrings,
        hat: hat ?? this.hat,
        hatColor: hatColor ?? this.hatColor,
        outfit: outfit ?? this.outfit,
        outfitColor: outfitColor ?? this.outfitColor,
        pattern: pattern ?? this.pattern,
        background: background ?? this.background,
        backdrop: backdrop ?? this.backdrop,
      );

  static LearnerLook _fromMap(Map<String, int> m) => LearnerLook(
        skin: m['skin']!,
        face: m['face']!,
        cheeks: m['cheeks']!,
        eyes: m['eyes']!,
        eyeColor: m['eyeColor']!,
        brows: m['brows']!,
        mouth: m['mouth']!,
        hair: m['hair']!,
        hairColor: m['hairColor']!,
        facialHair: m['facialHair']!,
        glasses: m['glasses']!,
        glassesColor: m['glassesColor']!,
        earrings: m['earrings']!,
        hat: m['hat']!,
        hatColor: m['hatColor']!,
        outfit: m['outfit']!,
        outfitColor: m['outfitColor']!,
        pattern: m['pattern']!,
        background: m['background']!,
        backdrop: m['backdrop']!,
      );

  static int _index(Object? raw, int max, int fallback) {
    final value = raw is int
        ? raw
        : raw is num
            ? raw.toInt()
            : null;
    if (value == null || value < 0 || value >= max) return fallback;
    return value;
  }

  /// Reads a saved look. First-generation looks (with `shirt` and
  /// `expression`) are converted to the closest new pieces.
  factory LearnerLook.decode(Object? raw) {
    const base = LearnerLook();
    if (raw is! Map) return base;
    if (!raw.containsKey('outfit') && raw.containsKey('shirt')) {
      return _migrate(raw);
    }
    final defaults = base.toJson();
    return _fromMap({
      for (final entry in ranges.entries)
        entry.key: _index(raw[entry.key], entry.value, defaults[entry.key]!)
    });
  }

  static LearnerLook _migrate(Map raw) {
    const base = LearnerLook();
    int read(String key, int max, int fallback) =>
        _index(raw[key], max, fallback);
    // Old expressions: smile, calm, eyes closed, surprised.
    final expression = read('expression', 4, 0);
    // Old hairstyles mapped to their nearest new style.
    const hair = [2, 3, 5, 7, 4, 11, 1, 0];
    // Old headwear: none, beanie, bucket.
    const hat = [0, 1, 4];
    return LearnerLook(
      skin: read('skin', 15, base.skin),
      eyeColor: read('eye', 5, 0),
      eyes: const [0, 0, 2, 1][expression],
      mouth: const [0, 7, 0, 6][expression],
      brows: expression == 3 ? 3 : 1,
      hair: hair[read('hair', 8, 0)],
      hairColor: read('hairColor', 6, base.hairColor),
      glasses: read('glasses', 3, 0),
      glassesColor: read('glassesColor', 5, base.glassesColor),
      hat: hat[read('hat', 3, 0)],
      hatColor: read('hatColor', 5, base.hatColor),
      outfitColor: read('shirt', 9, base.outfitColor),
      background: read('background', 20, base.background),
      backdrop: 0,
    );
  }

  /// Saved account avatar, or a varied stand-in when a person has no
  /// portrait yet.
  factory LearnerLook.fromAvatar(Object? avatar, {String seed = ''}) {
    if (avatar is Map && avatar['look'] is Map) {
      return LearnerLook.decode(avatar['look']);
    }
    if (seed.isEmpty) return const LearnerLook();
    final hash = seed.codeUnits.fold<int>(7, (sum, unit) => sum * 31 + unit);
    return LearnerLook.random(math.Random(hash));
  }

  /// A cheerful random look. Bold extras (hats, shades, fantasy colours)
  /// turn up now and then, so most results still look like a person.
  factory LearnerLook.random(math.Random r) {
    int pick(int count) => r.nextInt(count);
    int sometimes(double chance, int count) =>
        r.nextDouble() < chance ? 1 + r.nextInt(count - 1) : 0;
    return LearnerLook(
      skin: r.nextDouble() < .05 ? 16 + pick(4) : pick(16),
      face: pick(faceShapes.length),
      cheeks: r.nextDouble() < .7 ? 1 + pick(3) : pick(cheekStyles.length),
      eyes: r.nextDouble() < .55 ? pick(2) : pick(eyeStyles.length),
      eyeColor: pick(eyeColors.length),
      brows: 1 + pick(browStyles.length - 1),
      mouth: pick(mouthStyles.length),
      hair: 1 + pick(hairStyles.length - 1),
      hairColor: r.nextDouble() < .2 ? 10 + pick(6) : pick(10),
      facialHair: sometimes(.18, facialHairStyles.length),
      glasses: sometimes(.35, glassesStyles.length),
      glassesColor: pick(glassesColors.length),
      earrings: sometimes(.25, earringStyles.length),
      hat: sometimes(.4, hatStyles.length),
      hatColor: pick(hatColors.length),
      outfit: pick(outfitStyles.length),
      outfitColor: pick(outfitColors.length),
      pattern: r.nextDouble() < .55 ? 0 : pick(patterns.length),
      background: pick(backgrounds.length),
      backdrop: pick(backdrops.length),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LearnerLook &&
      ranges.keys.every((key) => other.valueOf(key) == valueOf(key));

  @override
  int get hashCode => Object.hashAll(toJson().values);
}
