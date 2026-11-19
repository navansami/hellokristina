import assert from 'node:assert/strict';
import { feedEvents, searchPattern, personCard, STREAK_MILESTONES } from '../server/social.js';

// A finished lesson always posts; level-ups and streak milestones post once.
assert.deepEqual(feedEvents({ before: { xp: 10, streak: 1 }, after: { xp: 30, streak: 1 }, lessonId: 'hello' }), [{ type: 'lesson', lessonId: 'hello' }]);
assert.deepEqual(feedEvents({ before: { xp: 30, streak: 2 }, after: { xp: 45, streak: 3 } }), [{ type: 'levelUp', level: 2 }, { type: 'streak', streak: 3 }]);
assert.deepEqual(feedEvents({ before: { xp: 50, streak: 7 }, after: { xp: 60, streak: 7 } }), [], 'same-day sessions repeat nothing');
assert.deepEqual(feedEvents({ before: { xp: 0, streak: 5 }, after: { xp: 10, streak: 6 } }), []);
assert(STREAK_MILESTONES.includes(7) && STREAK_MILESTONES.includes(100));
// Search text is safe to put in a regular expression.
assert.equal(searchPattern('@Ana.S'), String.raw`Ana\.S`);
assert.equal(searchPattern('a+b(c)'), String.raw`a\+b\(c\)`);
assert.equal(searchPattern('  '), '');
assert.doesNotThrow(() => new RegExp(`^${searchPattern('[(*')}`));
// Public cards never include email or password data.
const card = personCard({ _id: 'x', name: 'Ana', username: 'ana', email: 'a@b.c', passwordHash: 'h', xp: 120, streak: 4 }, { youFollow: true });
assert.deepEqual(Object.keys(card).sort(), ['avatar', 'followsYou', 'id', 'level', 'name', 'streak', 'username', 'xp', 'youFollow']);
assert.equal(card.level, 3);
console.log('Feed events, safe search and public cards pass.');
