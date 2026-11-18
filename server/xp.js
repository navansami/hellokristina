// Session XP and levels. lib/game/progression.dart mirrors these rules;
// scripts/check-xp.mjs and test/progression_test.dart pin the same table.

export function bestRun(answers) {
  let run = 0, best = 0;
  for (const right of answers) {
    run = right ? run + 1 : 0;
    if (run > best) best = run;
  }
  return best;
}

// Every finished session earns XP. A pass earns a completion bonus, two per
// correct answer, +5 for a perfect round and +5 for a run of five. Repeating a
// session earns half (rounded up). A failed session still earns one per
// correct answer, so effort always adds up.
export function sessionXp(answers, passed, firstTime) {
  const correct = answers.filter(Boolean).length;
  if (!passed) return correct;
  const perfect = correct === answers.length;
  const total = 10 + correct * 2 + (perfect ? 5 : 0) + (bestRun(answers) >= 5 ? 5 : 0);
  return firstTime ? total : Math.ceil(total / 2);
}

// Total XP needed to reach a level. Level 1 starts at 0; each level needs
// 20 more XP than the last (40, 60, 80, ...).
export function xpForLevel(level) {
  const n = Math.max(1, Math.floor(level));
  return 20 * (n - 1) + 10 * n * (n - 1);
}

export function levelForXp(xp) {
  let level = 1;
  while (xpForLevel(level + 1) <= xp) level++;
  return level;
}
