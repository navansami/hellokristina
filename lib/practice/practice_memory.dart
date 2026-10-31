part of '../main.dart';

/// Per-challenge Beta counts, kept on this device. Recent answers count more
/// than a long-ago streak, so the sampler can change its mind.
class PracticeMemory {
  static const storageKey = 'practice.itemMemory';

  static Future<Map<String, List<int>>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final memory = <String, List<int>>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is List && value.length >= 2 && value[0] is num && value[1] is num) {
          memory[entry.key.toString()] = [
            (value[0] as num).toInt().clamp(0, 40),
            (value[1] as num).toInt().clamp(0, 40),
          ];
        }
      }
      return memory;
    } catch (_) {
      return {};
    }
  }

  static Future<void> record(
      List<Question> questions, List<bool> answers) async {
    final memory = await load();
    for (var i = 0; i < answers.length && i < questions.length; i++) {
      final id = questions[i].id;
      if (id.isEmpty) continue;
      final prior = memory[id] ?? [0, 0];
      var correct = prior[0], wrong = prior[1];
      if (correct + wrong >= 8) {
        correct = (correct * .7).round();
        wrong = (wrong * .7).round();
      }
      if (answers[i]) {
        correct++;
      } else {
        wrong++;
      }
      memory[id] = [correct, wrong];
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(storageKey, jsonEncode(memory));
  }
}
