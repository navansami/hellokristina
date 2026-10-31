import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
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
console.log('Course valid: 2 units, 12 lessons, 48 challenges; Flutter bundle matches.');
