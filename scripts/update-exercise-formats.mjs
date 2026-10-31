import { readFileSync, writeFileSync } from 'node:fs';
const path = new URL('../curriculum/serbian-en.v1.json', import.meta.url);
const course = JSON.parse(readFileSync(path, 'utf8'));
if (course.version !== 3) throw new Error('This migration expects course version 3');
const clean = text => text.replace(/[.,!?;:]/g, '').trim();
const key = text => clean(text).toLowerCase();
const words = text => clean(text).split(/\s+/).filter(Boolean);
const englishFillers = ['tomorrow', 'bread', 'they', 'here', 'please'];
const serbianFillers = ['sutra', 'hleb', 'oni', 'ovde', 'molim'];
function bank(answer, candidates, language) {
  const correct = words(answer);
  const extras = [];
  for (const candidate of [...candidates, ...(language === 'en' ? englishFillers : serbianFillers)]) {
    for (const token of words(candidate)) {
      if (!correct.some(word => key(word) === key(token)) && !extras.some(word => key(word) === key(token))) extras.push(token);
      if (extras.length === 3) return [...correct, ...extras];
    }
  }
  return [...correct, ...extras];
}
function sourceSentence(lesson, question) {
  const word = key(question.audioText || question.answer);
  if (lesson.id === 'numbers') {
    const table = {
      jedan: ['Ovo je jedan pas.', 'This is one dog.', 'jedan'],
      dva: ['Ovo su dva psa.', 'These are two dogs.', 'dva'],
      tri: ['Ovo su tri psa.', 'These are three dogs.', 'tri'],
    };
    if (table[word]) return { phrase: table[word][0], meaning: table[word][1], missing: table[word][2], audioText: question.audioText, audio: question.audio };
  }
  if (lesson.id === 'polite') {
    const table = {
      molim: ['Čaj, molim.', 'Tea, please.', 'molim'],
      izvini: ['Izvini, gde je stanica?', 'Excuse me, where is the station?', 'Izvini'],
      da: ['Da, molim.', 'Yes, please.', 'Da'],
    };
    if (table[word]) return { phrase: table[word][0], meaning: table[word][1], missing: table[word][2], audioText: question.audioText, audio: question.audio };
  }
  if (lesson.id === 'time') {
    const table = {
      danas: ['Danas je ponedeljak.', 'Today is Monday.', 'Danas'],
      sutra: ['Sutra je ponedeljak.', 'Tomorrow is Monday.', 'Sutra'],
      sada: ['Sada sam kod kuće.', 'I am at home now.', 'Sada'],
    };
    if (table[word]) return { phrase: table[word][0], meaning: table[word][1], missing: table[word][2], audioText: question.audioText, audio: question.audio };
  }
  const sentence = lesson.challenges.find(q => q.type === 'Arrange the words');
  if (!sentence) throw new Error(`A reviewed sentence is required for ${lesson.id}`);
  return { phrase: sentence.answer, meaning: sentence.prompt, audioText: sentence.audioText, audio: sentence.audio };
}
function cloze(lesson, question, index) {
  const source = sourceSentence(lesson, question);
  const tokens = source.phrase.match(/[\p{L}\p{N}]+/gu);
  const names = ['ana', 'kristina', 'miloš', 'zara'];
  const functional = ['ja', 'je', 'se', 'sam', 'si', 'smo', 'ste', 'u', 'i'];
  const content = tokens.filter(token => !names.includes(key(token)) && !functional.includes(key(token)));
  const eligible = content.length ? content : tokens.filter(token => !names.includes(key(token)));
  const answer = source.missing || eligible[index % eligible.length];
  const offset = source.phrase.indexOf(answer);
  const prompt = source.phrase.slice(0, offset) + '___' + source.phrase.slice(offset + answer.length);
  const wrong = lesson.vocabulary.map(word => word.latin).filter(word => words(word).length === 1 && key(word) !== key(answer));
  const choices = [answer];
  for (const candidate of [...wrong, ...serbianFillers]) {
    if (!choices.some(word => key(word) === key(candidate))) choices.push(candidate);
    if (choices.length === 3) break;
  }
  return { ...question, type: 'Complete the sentence', prompt, translation: source.meaning, answer, options: choices,
    audioText: source.audioText, audio: source.audio, answerLanguage: 'sr',
    explanation: `${source.phrase} — ${source.meaning}` };
}
for (const unit of course.units) for (const lesson of unit.lessons) {
  // Keep the original reviewed sentence as the source for cloze construction.
  const original = structuredClone(lesson);
  lesson.challenges = original.challenges.map((question, index) => {
    const q = { ...question };
    if (q.type === 'Choose the meaning' || q.type === 'Listen and choose') {
      const answer = clean(q.answer.replace(/\s*\([^)]*\)/g, ''));
      const scriptTask = /[А-Яа-яђјљњћџ]/.test(q.prompt) && key(answer) === key(q.audioText);
      if (q.type === 'Choose the meaning' && words(answer).length === 1 && !scriptTask) return cloze(original, q, index);
      q.type = q.type === 'Listen and choose' ? 'Listen and arrange' : 'Arrange the words';
      q.prompt = q.type === 'Listen and arrange' ? 'Listen and build the translation.' : q.prompt.startsWith('What does') ? q.audioText : q.prompt;
      q.answer = answer;
      q.answerLanguage = scriptTask ? 'sr' : 'en';
      q.options = bank(answer, original.challenges[index].options.filter(option => key(option) !== key(original.challenges[index].answer)), q.answerLanguage);
    } else if (q.type === 'Translate to Serbian') {
      if (words(q.answer).length === 1) return cloze(original, q, index);
      q.type = 'Arrange the words';
      q.answer = clean(q.answer);
      q.answerLanguage = 'sr';
      q.options = bank(q.answer, lesson.vocabulary.map(word => word.latin), 'sr');
    } else if (q.type === 'Arrange the words') {
      q.answer = clean(q.answer);
      q.answerLanguage = 'sr';
      q.options = bank(q.answer, [...q.options.filter(word => !words(q.answer).some(token => key(token) === key(word))), ...lesson.vocabulary.map(word => word.latin)], 'sr');
    }
    return q;
  });
}
course.version = 4;
course.contentStage = 'Expanded A1 path with translation word banks, target-language sentence completion, listening and checkpoints';
writeFileSync(path, JSON.stringify(course, null, 2) + '\n');
writeFileSync(new URL('../assets/course/serbian-en.v1.json', import.meta.url), JSON.stringify(course, null, 2) + '\n');
console.log('Migrated course to version 4.');
