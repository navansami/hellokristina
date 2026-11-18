import assert from 'node:assert/strict';
import { bestRun, sessionXp, xpForLevel, levelForXp } from '../server/xp.js';
const all = n => Array(n).fill(true);
assert.equal(bestRun([true, true, false, true, true, true]), 3);
// Perfect first pass of 8: 10 + 16 + 5 perfect + 5 combo.
assert.equal(sessionXp(all(8), true, true), 36);
assert.equal(sessionXp(all(12), true, true), 44);
// Repeats earn half, rounded up.
assert.equal(sessionXp(all(8), true, false), 18);
// 6 of 8 with a broken run: 10 + 12, no bonuses.
const six = [true, true, true, false, true, true, true, false];
assert.equal(sessionXp(six, true, true), 22);
assert.equal(sessionXp(six, true, false), 11);
// Failed sessions still earn one per correct answer.
assert.equal(sessionXp([true, false, false, true, false, false, false, false], false, true), 2);
assert.deepEqual([1, 2, 3, 4, 5, 10].map(xpForLevel), [0, 40, 100, 180, 280, 1080]);
assert.deepEqual([0, 39, 40, 99, 100, 1080].map(levelForXp), [1, 1, 2, 2, 3, 10]);
console.log('Session XP, repeat, failure and level thresholds pass.');
