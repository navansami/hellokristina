import assert from 'node:assert/strict';
import { practiceResult, validPracticeLength } from '../server/practice-rounds.js';
let prior = { completedRounds: [], completedLessons: [] };
for (let i = 0; i < 5; i++) {
  const result = practiceResult(prior, 'hello', i, true);
  assert.equal(result.count, i + 1);
  assert.equal(result.circleComplete, i === 4);
  assert.equal(result.newRound, true);
  prior.completedRounds.push(result.key);
  assert.equal(practiceResult(prior, 'hello', i, true).newRound, false);
}
assert.equal(practiceResult({completedRounds:[]}, 'hello', 0, false).count, 0);
assert.equal(practiceResult({completedLessons:['hello']}, 'hello', 0, true).newRound, false);
assert.equal(practiceResult({completedLessons:['hello']}, 'hello', 0, true).count, 5);
assert.equal(practiceResult({}, 'hello', undefined, true).circleComplete, true);
assert.equal(practiceResult({completedRounds:['hello:legacy']}, 'hello', undefined, true).newRound, false);
const checkpoint = { type: 'checkpoint' };
const practice = { type: 'challenge' };
for (const count of [8, 10, 12]) {
  assert.equal(validPracticeLength(checkpoint, 0, count), true);
  assert.equal(validPracticeLength(practice, 2, count), true);
}
assert.equal(validPracticeLength(checkpoint, 0, 7), false);
assert.equal(validPracticeLength(practice, 0, 13), false);
assert.equal(validPracticeLength(practice, undefined, 5), true);
console.log('Five-round progress, retries, failures and legacy completions pass.');
