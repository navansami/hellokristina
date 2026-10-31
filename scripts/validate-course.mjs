import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { starterCourse, validateCourse } from '../server/course.js';

const bundled = JSON.parse(readFileSync(new URL('../assets/course/serbian-en.v1.json', import.meta.url), 'utf8'));
assert.deepEqual(bundled, starterCourse, 'Flutter bundle must match the published seed');
const course = validateCourse(starterCourse);
const lessons = course.units.flatMap(unit => unit.lessons);
assert.equal(course.sourceLanguage, 'en');
assert.equal(course.targetLanguage, 'sr');
assert.equal(course.status, 'published');
assert.equal(lessons.length, 12);
assert.equal(lessons.reduce((sum, lesson) => sum + lesson.challenges.length, 0), 48);
assert(lessons.every(lesson => lesson.theory.body && lesson.vocabulary.length));
const clips = new Map();
for (const lesson of lessons) {
  for (const word of lesson.vocabulary) clips.set(word.audio, word.latin);
  for (const question of lesson.challenges) clips.set(question.audio, question.audioText);
}
for (const [path, input] of clips) {
  assert(input, `Missing Serbian audio text for ${path}`);
  const hash = createHash('sha256').update(input).digest('hex').slice(0, 12);
  assert.equal(path, `audio/serbian/${hash}.mp3`, `Incorrect audio mapping for ${input}`);
  const fullPath = new URL(`../assets/${path}`, import.meta.url);
  assert(existsSync(fullPath), `Missing clip for ${input}`);
  const bytes = readFileSync(fullPath);
  assert(bytes.length > 1000, `Empty clip for ${input}`);
  assert(bytes[0] === 0xff || bytes.subarray(0, 3).toString() === 'ID3', `Invalid MP3 for ${input}`);
}
console.log(`Course valid: 2 units, 12 lessons, 48 challenges, ${clips.size} MP3 clips; Flutter bundle matches.`);
