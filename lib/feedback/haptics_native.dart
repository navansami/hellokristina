import 'package:flutter/services.dart';

int _generation = 0;
void cancelPulse() {
  _generation++;
}

Future<void> pulse(List<int> pattern, {bool strong = false}) async {
  final generation = ++_generation;
  try {
    for (var i = 0; i < pattern.length; i += 2) {
      if (generation != _generation) return;
      if (strong) {
        await HapticFeedback.mediumImpact();
      } else if (pattern.first <= 8) {
        await HapticFeedback.selectionClick();
      } else {
        await HapticFeedback.lightImpact();
      }
      if (i + 2 < pattern.length)
        await Future<void>.delayed(
            Duration(milliseconds: pattern[i] + pattern[i + 1]));
    }
  } catch (_) {/* Unsupported desktop platforms remain silent. */}
}
