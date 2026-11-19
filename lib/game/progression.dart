/// Session XP and levels. `server/xp.js` mirrors these rules exactly.
library;

int bestRun(List<bool> answers) {
  var run = 0, best = 0;
  for (final right in answers) {
    run = right ? run + 1 : 0;
    if (run > best) best = run;
  }
  return best;
}

/// The XP a finished session earns, itemised for the completion screen.
class SessionReward {
  final int completion, accuracy, perfect, combo;
  final bool passed, firstTime;
  const SessionReward(
      {this.completion = 0,
      this.accuracy = 0,
      this.perfect = 0,
      this.combo = 0,
      this.passed = false,
      this.firstTime = true});

  int get subtotal => completion + accuracy + perfect + combo;

  /// Repeats earn half, rounded up. Failed sessions are never halved.
  int get total => passed && !firstTime ? (subtotal + 1) ~/ 2 : subtotal;
}

SessionReward sessionReward(List<bool> answers,
    {required bool passed, required bool firstTime}) {
  final correct = answers.where((right) => right).length;
  if (!passed) {
    return SessionReward(accuracy: correct, firstTime: firstTime);
  }
  return SessionReward(
      completion: 10,
      accuracy: correct * 2,
      perfect: answers.isNotEmpty && correct == answers.length ? 5 : 0,
      combo: bestRun(answers) >= 5 ? 5 : 0,
      passed: true,
      firstTime: firstTime);
}

/// Total XP needed to reach [level]: 0, 40, 100, 180, 280, ...
int xpForLevel(int level) {
  final n = level < 1 ? 1 : level;
  return 20 * (n - 1) + 10 * n * (n - 1);
}

int levelForXp(int xp) {
  var level = 1;
  while (xpForLevel(level + 1) <= xp) {
    level++;
  }
  return level;
}

/// Fraction of the way from the current level to the next.
double levelProgress(int xp) {
  final level = levelForXp(xp);
  final start = xpForLevel(level), end = xpForLevel(level + 1);
  return (xp - start) / (end - start);
}

/// Daily streak after activity on [today], given the last active day.
int nextStreak(int streak, DateTime? lastActive, DateTime today) {
  if (lastActive == null) return 1;
  final last = DateTime(lastActive.year, lastActive.month, lastActive.day);
  final day = DateTime(today.year, today.month, today.day);
  final gap = day.difference(last).inDays;
  if (gap <= 0) return streak < 1 ? 1 : streak;
  if (gap == 1) return streak + 1;
  return 1;
}

/// Ring segments a passed session fills (mirrors `segmentsEarned` in
/// server/xp.js). Checkpoints and assessments fill all five on a pass.
int segmentsEarned(List<bool> answers,
    {required bool passed, String kind = 'challenge'}) {
  if (!passed || answers.isEmpty) return 0;
  if (kind != 'challenge') return 5;
  final correct = answers.where((right) => right).length;
  if (correct == answers.length) return 3;
  return correct * 100 >= 85 * answers.length ? 2 : 1;
}

/// The session keys a pass claims: the played session first, then the lowest
/// open ones (mirrors `claimRounds` in server/xp.js).
List<String> claimRounds(
    Set<String> completed, String lessonId, int roundIndex, int segments) {
  final order = <int>{roundIndex, 0, 1, 2, 3, 4};
  final claimed = <String>[];
  for (final i in order) {
    if (claimed.length >= segments) break;
    final key = '$lessonId:$i';
    if (!completed.contains(key)) claimed.add(key);
  }
  return claimed;
}
