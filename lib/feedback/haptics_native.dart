import 'package:flutter/services.dart';

int _generation = 0;
void cancelPulse() {
  _generation++;
}

/// Plays a vibration pattern (on, off, on, ... in ms) as a run of haptic
/// taps. Longer pulses map to firmer taps; [strong] makes each one firmer.
Future<void> pulse(List<int> pattern, {bool strong = false}) async {
  final generation = ++_generation;
  try {
    for (var i = 0; i < pattern.length; i += 2) {
      if (generation != _generation) return;
      final on = pattern[i] + (strong ? 20 : 0);
      if (on <= 10) {
        await HapticFeedback.selectionClick();
      } else if (on <= 25) {
        await HapticFeedback.lightImpact();
      } else if (on <= 50) {
        await HapticFeedback.mediumImpact();
      } else {
        await HapticFeedback.heavyImpact();
      }
      if (i + 1 < pattern.length) {
        await Future<void>.delayed(
            Duration(milliseconds: pattern[i] + pattern[i + 1]));
      }
    }
  } catch (_) {/* Unsupported desktop platforms remain silent. */}
}
