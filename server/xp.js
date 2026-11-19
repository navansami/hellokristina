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

// Ring segments a passed session fills: a flawless session (no misses,
// including retries) fills 3, 85% or better fills 2, any other pass fills 1.
export function segmentsEarned(answers, passed) {
  if (!passed || !answers.length) return 0;
  const correct = answers.filter(Boolean).length;
  if (correct === answers.length) return 3;
  return correct * 100 >= 85 * answers.length ? 2 : 1;
}

// Which of a lesson's five session keys a pass claims: the played session
// first (if still open), then the lowest open ones, up to `segments` keys.
export function claimRounds(completed, lessonId, roundIndex, segments) {
  const done = new Set(completed || []);
  const order = [roundIndex, 0, 1, 2, 3, 4].filter((value, index, all) => all.indexOf(value) === index);
  const claimed = [];
  for (const i of order) {
    if (claimed.length >= segments) break;
    const key = `${lessonId}:${i}`;
    if (!done.has(key)) claimed.push(key);
  }
  return claimed;
}
