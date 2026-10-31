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
assert.equal(course.version, 4);
assert.equal(course.units.length, 11);
assert.equal(lessons.length, 68);
assert.equal(lessons.reduce((sum, lesson) => sum + lesson.challenges.length, 0), 424);
assert.equal(lessons.filter(lesson => lesson.type === 'assessment').length, 1);
assert.equal(lessons.filter(lesson => lesson.type === 'checkpoint').length, 11);
assert(lessons.every(lesson => lesson.type === 'challenge' || lesson.minPassPercent >= 75));
assert(lessons.every(lesson => lesson.challenges.some(question => question.type.startsWith('Listen'))));
assert(lessons.every(lesson => lesson.theory.body && lesson.vocabulary.length));
assert(lessons.every(lesson => lesson.challenges.every(item => !['Choose the meaning', 'Translate to Serbian', 'Listen and choose'].includes(item.type))));
for (const lesson of lessons) for (const item of lesson.challenges) {
  if (['Arrange the words','Listen and arrange'].includes(item.type)) {
    assert(item.options.length > item.answer.split(' ').length, `Distractors required for ${item.id}`);
  }
}

const targetWords = new Set(lessons.flatMap(lesson => [
  ...lesson.vocabulary.map(word => word.latin),
  ...lesson.challenges.map(item => item.audioText || ''),
]).flatMap(text => text.toLowerCase().match(/[\p{L}\p{N}]+/gu) || []));
for (const lesson of lessons) for (const item of lesson.challenges) {
  if (item.type === 'Complete the sentence') for (const option of item.options) {
    assert(targetWords.has(option.toLowerCase()), `Target-language option required for ${item.id}: ${option}`);
  }
}
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
console.log(`Course valid: ${course.units.length} units, ${lessons.length} lessons, 424 challenges, ${clips.size} MP3 clips; Flutter bundle matches.`);
