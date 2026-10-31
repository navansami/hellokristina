import { createRequire } from 'node:module';
import { z } from 'zod';

const require = createRequire(import.meta.url);
export const starterCourse = require('../curriculum/serbian-en.v1.json');

const challenge = z.object({
  id: z.string().min(1),
  type: z.enum(['Choose the meaning', 'Translate to Serbian', 'Arrange the words', 'Type the answer', 'Choose the image']),
  prompt: z.string().min(1),
  answer: z.string().min(1),
  options: z.array(z.string()),
  explanation: z.string().min(1),
});
const vocabulary = z.object({
  latin: z.string().min(1), cyrillic: z.string().min(1),
  english: z.string().min(1), pronunciation: z.string().min(1),
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
      type: z.literal('challenge'),
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
    for (const item of lesson.challenges) {
      if (item.type === 'Arrange the words') {
        const tokens = item.options.slice();
        for (const word of item.answer.split(' ')) {
          const i = tokens.indexOf(word);
          if (i < 0) throw new Error(`Missing arrangement token in ${item.id}`);
          tokens.splice(i, 1);
        }
      } else if (item.type !== 'Type the answer' && !item.options.includes(item.answer)) {
        throw new Error(`Missing answer option in ${item.id}`);
      }
    }
  }
  return course;
}

validateCourse(starterCourse);
