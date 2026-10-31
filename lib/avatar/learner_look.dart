import 'package:flutter/material.dart';

/// A learner portrait assembled from recolorable pieces.
class LearnerLook {
  final int skin;
  final int body;
  final int eye;
  final int expression;
  final int hair;
  final int hairColor;
  final int glasses;
  final int glassesColor;
  final int hat;
  final int hatColor;
  final int shirt;
  final int background;

  const LearnerLook({
    this.skin = 6,
    this.body = 3,
    this.eye = 0,
    this.expression = 0,
    this.hair = 0,
    this.hairColor = 1,
    this.glasses = 0,
    this.glassesColor = 1,
    this.hat = 0,
    this.hatColor = 1,
    this.shirt = 4,
    this.background = 0,
  });

  static const skins = [
    Color(0xFF4A2C24),
    Color(0xFF5C382C),
    Color(0xFF6B4334),
    Color(0xFF7A4E3A),
    Color(0xFF8A5A42),
    Color(0xFF9A684C),
    Color(0xFFA87456),
    Color(0xFFB88362),
    Color(0xFFC49270),
    Color(0xFFD0A27E),
    Color(0xFFDBB08C),
    Color(0xFFE4BE9C),
    Color(0xFFECCAAC),
    Color(0xFFF3D6BC),
    Color(0xFFF8E0CC),
  ];
  static const eyeColors = [
    Color(0xFF3A2C24),
    Color(0xFFC2652A),
    Color(0xFFC6A23A),
    Color(0xFF3E8C48),
    Color(0xFF3A8C8A),
  ];
  static const hairColors = [
    Color(0xFF2A241F),
    Color(0xFF4A3428),
    Color(0xFF6E302C),
    Color(0xFF7A4E32),
    Color(0xFF8E4034),
    Color(0xFFC6A15A),
  ];
  static const glassesColors = [
    Color(0xFF8B6AD6),
    Color(0xFF3C7DDB),
    Color(0xFF3E9A55),
    Color(0xFFE08A2E),
    Color(0xFFD64545),
  ];
  static const hatColors = [
    Color(0xFF8B6AD6),
    Color(0xFF3C7DDB),
    Color(0xFF3E9A55),
    Color(0xFFF2D34A),
    Color(0xFFE08A2E),
  ];
  static const shirts = [
    Color(0xFFB07CDB),
    Color(0xFF4AA3E8),
    Color(0xFF5EBE6A),
    Color(0xFFF2D34A),
    Color(0xFFF0A04A),
    Color(0xFFD4536A),
    Color(0xFFF2B4C8),
    Color(0xFFF4F4F4),
    Color(0xFF4E555C),
  ];
  static const backgrounds = [
    Color(0xFFF6E7A8),
    Color(0xFFE7E7E7),
    Color(0xFF8D8D8D),
    Color(0xFF5C5C5C),
    Color(0xFFF3D6E4),
    Color(0xFFE4D4F5),
    Color(0xFFC9B6F2),
    Color(0xFFB7D9F8),
    Color(0xFF9FD4F5),
    Color(0xFF6AA8D8),
    Color(0xFF2F6FA8),
    Color(0xFFD5F3EA),
    Color(0xFFB7E6D4),
    Color(0xFF8FD6B8),
    Color(0xFF6FCB7A),
    Color(0xFFB7D96A),
    Color(0xFFF3D56A),
    Color(0xFFF6C27A),
    Color(0xFFF3B4C4),
    Color(0xFFE8A0B8),
  ];

  static const bodyCount = 4;
  static const expressionCount = 4;
  static const hairStyleCount = 8;
  static const glassesStyleCount = 3;
  static const hatStyleCount = 3;

  Color get skinColor => skins[skin];
  Color get eyeColor => eyeColors[eye];
  Color get hairColorValue => hairColors[hairColor];
  Color get glassesColorValue => glassesColors[glassesColor];
  Color get hatColorValue => hatColors[hatColor];
  Color get shirtColor => shirts[shirt];
  Color get backgroundColor => backgrounds[background];

  String get backgroundHex {
    final hex =
        backgroundColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
    return '#${hex.toUpperCase()}';
  }

  LearnerLook copyWith({
    int? skin,
    int? body,
    int? eye,
    int? expression,
    int? hair,
    int? hairColor,
    int? glasses,
    int? glassesColor,
    int? hat,
    int? hatColor,
    int? shirt,
    int? background,
  }) =>
      LearnerLook(
        skin: skin ?? this.skin,
        body: body ?? this.body,
        eye: eye ?? this.eye,
        expression: expression ?? this.expression,
        hair: hair ?? this.hair,
        hairColor: hairColor ?? this.hairColor,
        glasses: glasses ?? this.glasses,
        glassesColor: glassesColor ?? this.glassesColor,
        hat: hat ?? this.hat,
        hatColor: hatColor ?? this.hatColor,
        shirt: shirt ?? this.shirt,
        background: background ?? this.background,
      );

  Map<String, int> toJson() => {
        'skin': skin,
        'body': body,
        'eye': eye,
        'expression': expression,
        'hair': hair,
        'hairColor': hairColor,
        'glasses': glasses,
        'glassesColor': glassesColor,
        'hat': hat,
        'hatColor': hatColor,
        'shirt': shirt,
        'background': background,
      };

  static int _index(Object? raw, int max, int fallback) {
    final value = raw is int ? raw : raw is num ? raw.toInt() : null;
    if (value == null || value < 0 || value >= max) return fallback;
    return value;
  }

  factory LearnerLook.decode(Object? raw) {
    const base = LearnerLook();
    if (raw is! Map) return base;
    return LearnerLook(
      skin: _index(raw['skin'], skins.length, base.skin),
      body: _index(raw['body'], bodyCount, base.body),
      eye: _index(raw['eye'], eyeColors.length, base.eye),
      expression: _index(raw['expression'], expressionCount, base.expression),
      hair: _index(raw['hair'], hairStyleCount, base.hair),
      hairColor: _index(raw['hairColor'], hairColors.length, base.hairColor),
      glasses: _index(raw['glasses'], glassesStyleCount, base.glasses),
      glassesColor:
          _index(raw['glassesColor'], glassesColors.length, base.glassesColor),
      hat: _index(raw['hat'], hatStyleCount, base.hat),
      hatColor: _index(raw['hatColor'], hatColors.length, base.hatColor),
      shirt: _index(raw['shirt'], shirts.length, base.shirt),
      background: _index(raw['background'], backgrounds.length, base.background),
    );
  }

  /// Saved account avatar, or a varied stand-in when a person has no portrait yet.
  factory LearnerLook.fromAvatar(Object? avatar, {String seed = ''}) {
    if (avatar is Map && avatar['look'] is Map) {
      return LearnerLook.decode(avatar['look']);
    }
    if (seed.isEmpty) return const LearnerLook();
    final hash = seed.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return LearnerLook(
      skin: hash % skins.length,
      hair: hash % hairStyleCount,
      hairColor: hash % hairColors.length,
      shirt: hash % shirts.length,
      body: hash % bodyCount,
      background: hash % backgrounds.length,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LearnerLook &&
      other.skin == skin &&
      other.body == body &&
      other.eye == eye &&
      other.expression == expression &&
      other.hair == hair &&
      other.hairColor == hairColor &&
      other.glasses == glasses &&
      other.glassesColor == glassesColor &&
      other.hat == hat &&
      other.hatColor == hatColor &&
      other.shirt == shirt &&
      other.background == background;

  @override
  int get hashCode => Object.hash(skin, body, eye, expression, hair, hairColor,
      glasses, glassesColor, hat, hatColor, shirt, background);
}
