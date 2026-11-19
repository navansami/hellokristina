import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Warm cream canvas, indigo ink and candy accents: playful, but calm enough
// to read for a long session.
const bg = Color(0xFFFFFBF6);
const panel = Colors.white;
const panel2 = Color(0xFFECE7F3);
const ink = Color(0xFF221C3F);
const muted = Color(0xFF6D6890);
const orange = Color(0xFFF2622E);
const amberInk = Color(0xFFB4470C);
const peach = Color(0xFFFFEEDF);
const blue = Color(0xFF2F6BF0);
const sky = Color(0xFFEAF1FF);
const green = Color(0xFF13945E);
const mint = Color(0xFFE3F8EC);
const red = Color(0xFFD93848);
const blush = Color(0xFFFFEDEF);
const pink = Color(0xFFE93E7F);
const purple = Color(0xFF7356F0);
const sun = Color(0xFFFFC62E);
const teal = Color(0xFF13B5A6);

/// Rounded, bouncy display type for English headings and buttons. Serbian
/// letters and Cyrillic fall back to Nunito, which has them.
TextStyle display(double size,
        {Color color = ink,
        FontWeight weight = FontWeight.w600,
        double? height,
        double? letterSpacing}) =>
    GoogleFonts.fredoka(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        textStyle: TextStyle(
            fontFamilyFallback: [GoogleFonts.nunito().fontFamily ?? 'Nunito']));

/// Each unit of the trail has its own colour story.
class UnitTheme {
  final Color main, deep, light;
  const UnitTheme(this.main, this.deep, this.light);
  Color get glow => Color.lerp(main, Colors.white, .28)!;
  LinearGradient get gradient => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color.lerp(main, Colors.white, .12)!, main, deep]);
}

const unitThemes = [
  UnitTheme(Color(0xFFFF6B4A), Color(0xFFC9432A), Color(0xFFFFE6DF)), // coral
  UnitTheme(Color(0xFF7B5CFA), Color(0xFF5235C9), Color(0xFFEDE8FF)), // violet
  UnitTheme(Color(0xFF14B39C), Color(0xFF0B8574), Color(0xFFDDF7F2)), // teal
  UnitTheme(Color(0xFF3B82F6), Color(0xFF2259C4), Color(0xFFE3EEFF)), // blue
  UnitTheme(Color(0xFFFF9F1C), Color(0xFFC86F00), Color(0xFFFFF0D9)), // amber
  UnitTheme(Color(0xFFEC4899), Color(0xFFB8256F), Color(0xFFFFE4F1)), // pink
  UnitTheme(Color(0xFF22A45D), Color(0xFF167A43), Color(0xFFE0F5E8)), // green
  UnitTheme(Color(0xFF5B5BD6), Color(0xFF3D3DA8), Color(0xFFE8E8FF)), // indigo
  UnitTheme(
      Color(0xFFF2622E), Color(0xFFB8400F), Color(0xFFFFE9DE)), // tangerine
  UnitTheme(Color(0xFF0EA5C6), Color(0xFF087A94), Color(0xFFDDF4FA)), // lagoon
  UnitTheme(Color(0xFFA855F7), Color(0xFF7A2CC4), Color(0xFFF3E6FF)), // grape
];

UnitTheme unitTheme(int index) => unitThemes[index % unitThemes.length];
