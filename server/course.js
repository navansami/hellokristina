import { createRequire } from 'node:module';
import { z } from 'zod';

const require = createRequire(import.meta.url);
export const starterCourse = require('../curriculum/serbian-en.v1.json');

const challenge = z.object({
  id: z.string().min(1),
  type: z.enum(['Choose the meaning', 'Translate to Serbian', 'Arrange the words', 'Type the answer', 'Choose the image', 'Listen and choose', 'Listen and type', 'Listen and arrange', 'Complete the sentence']),
  prompt: z.string().min(1),
  answer: z.string().min(1),
  options: z.array(z.string()),
  explanation: z.string().min(1),
  translation: z.string().min(1).optional(),
  answerLanguage: z.string().regex(/^[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})?$/).optional(),
  audioText: z.string().min(1).optional(),
  audio: z.string().regex(/^audio\/serbian\/[a-f0-9]{12}\.mp3$/).optional(),
});
const vocabulary = z.object({
  latin: z.string().min(1), cyrillic: z.string().min(1),
  english: z.string().min(1), pronunciation: z.string().min(1),
  audio: z.string().regex(/^audio\/serbian\/[a-f0-9]{12}\.mp3$/).optional(),
});
export const courseSchema = z.object({
  schemaVersion: z.literal(1), id: z.string().regex(/^[a-z0-9-]{3,40}$/),
  title: z.string().min(1), sourceLanguage: z.string().min(2),
  targetLanguage: z.string().min(2), version: z.number().int().positive(),
  status: z.enum(['draft', 'published']), contentStage: z.string().min(1),
  sources: z.array(z.string().url()),
  units: z.array(z.object({
    id: z.string().min(1), level: z.string().min(1), title: z.string().min(1),
    subtitle: z.string().min(1), outcomes: z.array(z.string().min(1)).min(1),
    lessons: z.array(z.object({
      id: z.string().regex(/^[a-z0-9-]{2,80}$/), title: z.string().min(1),
      subtitle: z.string().min(1), icon: z.string().min(1), color: z.string().min(1),
      type: z.enum(['challenge', 'checkpoint', 'assessment']),
      minPassPercent: z.number().int().min(0).max(100).optional(),
      theory: z.object({ title: z.string().min(1), body: z.string().min(1) }),
      vocabulary: z.array(vocabulary).min(1), challenges: z.array(challenge).min(1),
    })).min(1),
  })).min(1),
});

export function validateCourse(value) {
  const course = courseSchema.parse(value);
  const lessons = course.units.flatMap(unit => unit.lessons);
  const ids = lessons.map(lesson => lesson.id);
  if (new Set(ids).size !== ids.length) throw new Error('Duplicate lesson IDs');
  for (const lesson of lessons) {
    const challengeIds = lesson.challenges.map(item => item.id);
    if (new Set(challengeIds).size !== challengeIds.length) throw new Error(`Duplicate challenge IDs in ${lesson.id}`);
    if (lesson.type !== 'challenge' && !lesson.minPassPercent) throw new Error(`Checkpoint requires a passing score: ${lesson.id}`);
    for (const item of lesson.challenges) {
      if (item.type === 'Complete the sentence' && (!item.translation || (item.prompt.match(/___/g) || []).length !== 1 || item.options.length !== 3 || new Set(item.options).size !== 3 || item.options.filter(option => option === item.answer).length !== 1 || item.answerLanguage !== course.targetLanguage || item.options.some(option => /\s/.test(option)))) throw new Error(`Invalid sentence completion in ${item.id}`);
      if (item.type.startsWith('Listen') && (!item.audioText || !item.audio)) throw new Error(`Listening audio is required in ${item.id}`);
      if (item.type === 'Arrange the words' || item.type === 'Listen and arrange') {
        const tokens = item.options.slice();
        for (const word of item.answer.split(' ')) {
          const i = tokens.indexOf(word);
          if (i < 0) throw new Error(`Missing arrangement token in ${item.id}`);
          tokens.splice(i, 1);
        }
      } else if (item.type !== 'Type the answer' && item.type !== 'Listen and type' && !item.options.includes(item.answer)) {
        throw new Error(`Missing answer option in ${item.id}`);
      }
    }
  }
  return course;
}

validateCourse(starterCourse);

export function lessonPassed(lesson, answers) {
  return answers.filter(Boolean).length * 100 >= (lesson.minPassPercent || 0) * answers.length;
}
