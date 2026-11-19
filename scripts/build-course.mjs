// Builds curriculum/serbian-en.v1.json (and the Flutter copy) from the
// authored source in curriculum/src/serbian-a1.mjs, plus a review sheet for a
// native speaker at curriculum/REVIEW.md. Deterministic: same source, same
// output.
import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { course, units } from '../curriculum/src/serbian-a1.mjs';

const previous = JSON.parse(readFileSync('curriculum/serbian-en.v1.json', 'utf8'));
const hash = text => createHash('sha256').update(text).digest('hex');
const audioFor = text => `audio/serbian/${hash(text).slice(0, 12)}.mp3`;
const pick = (seed, n) => parseInt(hash(seed).slice(0, 8), 16) % n;
const strip = text => text.replace(/[.,!?;:„“”"()—]/g, ' ').replace(/\s+/g, ' ').trim();
const tokens = text => strip(text).split(' ').filter(Boolean);
const fold = text => text.toLowerCase();

// Serbian Latin → Cyrillic. Digraphs lj, nj and dž are always single letters
// in the words this course uses.
const cyr = { a:'а',b:'б',v:'в',g:'г',d:'д',đ:'ђ',e:'е',ž:'ж',z:'з',i:'и',j:'ј',k:'к',l:'л',m:'м',n:'н',o:'о',p:'п',r:'р',s:'с',t:'т',ć:'ћ',u:'у',f:'ф',h:'х',c:'ц',č:'ч',š:'ш' };
const digraphs = { lj: 'љ', nj: 'њ', dž: 'џ' };
export function toCyrillic(latin) {
  let out = '';
  for (let i = 0; i < latin.length; i++) {
    const two = latin.slice(i, i + 2), lowerTwo = two.toLowerCase();
    if (digraphs[lowerTwo]) {
      const letter = digraphs[lowerTwo];
      out += two[0] === two[0].toUpperCase() && two[0] !== two[0].toLowerCase() ? letter.toUpperCase() : letter;
      i++;
      continue;
    }
    const ch = latin[i], lower = ch.toLowerCase();
    if (cyr[lower]) out += ch === lower ? cyr[lower] : cyr[lower].toUpperCase();
    else out += ch;
  }
  return out;
}

// A readable English respelling, one hyphenated chunk per syllable.
const vowelSound = { a: 'ah', e: 'eh', i: 'ee', o: 'oh', u: 'oo' };
const consonantSound = { c: 'ts', č: 'ch', ć: 'ch', đ: 'j', dž: 'j', j: 'y', lj: 'ly', nj: 'ny', š: 'sh', ž: 'zh', h: 'h' };
function respell(word) {
  const letters = [];
  const w = word.toLowerCase().replace(/[^a-zčćđšž-]/g, '');
  for (let i = 0; i < w.length; i++) {
    const two = w.slice(i, i + 2);
    if (two === 'lj' || two === 'nj' || two === 'dž') { letters.push(two); i++; } else letters.push(w[i]);
  }
  // Syllabic r (trg, Srbija, četvrtak) counts as a vowel between consonants.
  const plain = l => 'aeiou'.includes(l);
  const syllabic = letters.map((l, i) => l === 'r' && !plain(letters[i - 1] ?? '') && !plain(letters[i + 1] ?? ''));
  const vowelAt = new Map(letters.map((l, i) => [i, plain(l) || syllabic[i]]));
  const syllables = [];
  let current = '';
  for (let i = 0; i < letters.length; i++) {
    const l = letters[i];
    if (l === '-') { if (current) syllables.push(current); syllables.push('-'); current = ''; continue; }
    current += plain(l) ? vowelSound[l] : (consonantSound[l] ?? l);
    if (vowelAt.get(i)) {
      // Keep one consonant for the next syllable; give the rest of a cluster
      // to this one, unless the word ends.
      let j = i + 1;
      while (j < letters.length && !vowelAt.get(j) && letters[j] !== '-') j++;
      const cluster = j - i - 1;
      if (j >= letters.length) continue;
      if (letters[j] === '-') continue;
      // A consonant followed by r, l, v or j starts the next syllable
      // together: do-bro, Sr-bi-ja.
      const [first, second] = [letters[j - 2], letters[j - 1]];
      const glide = cluster >= 2 && (('rvj'.includes(second) && 'bpgkfdt'.includes(first)) || (second === 'l' && 'bpgkf'.includes(first)));
      const keep = Math.max(0, cluster - (glide ? 2 : 1));
      for (let k = 0; k < keep; k++) current += consonantSound[letters[i + 1 + k]] ?? letters[i + 1 + k];
      i += keep;
      syllables.push(current);
      current = '';
    }
  }
  if (current) {
    if (syllables.length && syllables[syllables.length - 1] !== '-' && !/[aeiou]/.test(current)) syllables[syllables.length - 1] += current;
    else syllables.push(current);
  }
  return syllables.join('-').replace(/-?-+-?/g, '-').replace(/^-|-$/g, '');
}
export const pronounce = latin => latin.split(/\s+/).map(respell).filter(Boolean).join(' ');

function words(spec) {
  return spec.split('|').map(entry => {
    const [latin, english, pronunciation] = entry.split('=').map(part => part?.trim());
    if (!latin || !english) throw new Error(`Bad word entry: ${entry}`);
    return { latin, cyrillic: toCyrillic(latin), english, pronunciation: pronunciation || pronounce(latin), audio: audioFor(latin) };
  });
}

/// Tiles for an arrangement: the answer's words plus distractors drawn from
/// the same lesson, never a word already in the answer.
function tiles(answer, pool, seed) {
  const answerWords = tokens(answer);
  const used = new Set(answerWords.map(fold));
  const candidates = [...new Set(pool.flatMap(tokens))].filter(word => !used.has(fold(word)));
  const want = answerWords.length <= 3 ? 3 : 2;
  const extra = [];
  for (let k = 0; extra.length < want && k < candidates.length; k++) {
    const word = candidates[(pick(seed, candidates.length) + k * 7) % candidates.length];
    if (!extra.some(item => fold(item) === fold(word))) extra.push(word);
  }
  if (extra.length < 1) throw new Error(`No distractors for ${seed}`);
  return [...answerWords, ...extra];
}

function rotate(options, seed) {
  const shift = pick(seed, options.length);
  return [...options.slice(shift), ...options.slice(0, shift)];
}

function challengesFor(lesson) {
  const out = [];
  const serbianPool = [...lesson.say.map(([sr]) => sr), ...words(lesson.words).map(word => word.latin)];
  const englishPool = [...lesson.say.map(([, en]) => en), ...words(lesson.words).map(word => word.english.replace(/\(.*?\)/g, '').split('/')[0])];
  lesson.say.forEach(([sr, en], i) => {
    const id = `${lesson.id}-s${i + 1}`;
    if (i % 2 === 0) {
      out.push({ id, type: 'Arrange the words', prompt: en, answer: strip(sr), options: tiles(sr, serbianPool, id), explanation: `${sr} — ${en}`, audioText: sr, audio: audioFor(sr), answerLanguage: 'sr' });
    } else {
      out.push({ id, type: 'Listen and arrange', prompt: 'Listen and build the translation.', answer: strip(en), options: tiles(en, englishPool, id), explanation: `You heard: ${sr} — ${en}`, audioText: sr, audio: audioFor(sr), answerLanguage: 'en' });
    }
  });
  (lesson.gaps || []).forEach(([prompt, answer, others, en], i) => {
    const id = `${lesson.id}-g${i + 1}`;
    const full = prompt.replace('___', answer);
    out.push({ id, type: 'Complete the sentence', prompt, answer, options: rotate([answer, ...others.split(' ')], id), explanation: `${full} — ${en}`, translation: en, audioText: full, audio: audioFor(full), answerLanguage: 'sr' });
  });
  (lesson.replies || []).forEach(([line, en, answer, wrong], i) => {
    const id = `${lesson.id}-r${i + 1}`;
    out.push({ id, type: 'Choose the reply', prompt: line, answer, options: rotate([answer, ...wrong], id), explanation: `“${line}” — “${answer}”`, translation: en, audioText: line, audio: audioFor(line), answerLanguage: 'sr' });
  });
  (lesson.read || []).forEach((item, i) => {
    const id = `${lesson.id}-t${i + 1}`;
    const spoken = item.audio || item.text.replace(/\n/g, ' ');
    out.push({ id, type: 'Read and answer', prompt: item.text, question: item.q, answer: item.a, options: rotate([item.a, ...item.wrong], id), explanation: item.en, audioText: spoken, audio: audioFor(spoken), answerLanguage: 'en' });
  });
  return out;
}

const renumber = (items, prefix) => items.map((item, i) => ({ ...item, id: `${prefix}-${i + 1}` }));

export function build() {
const builtUnits = units.map(unit => {
  const lessons = unit.lessons.map(lesson => ({
    id: lesson.id, title: lesson.title, subtitle: lesson.subtitle, icon: lesson.icon, color: lesson.color, type: 'challenge',
    theory: { title: lesson.grammar[0], body: lesson.grammar[1] },
    vocabulary: words(lesson.words),
    challenges: challengesFor(lesson),
  }));
  // A checkpoint mixes a sentence, a gap and a reply from every lesson.
  const mix = lessons.flatMap(lesson => [
    lesson.challenges.find(item => item.type === 'Complete the sentence'),
    lesson.challenges.find(item => item.type === 'Choose the reply'),
    lesson.challenges.find(item => item.type === 'Listen and arrange'),
  ].filter(Boolean));
  const checkpoint = {
    id: unit.checkpoint.id, title: unit.checkpoint.title, subtitle: unit.checkpoint.subtitle, icon: '🏅', color: 'orange', type: 'checkpoint', minPassPercent: 75,
    theory: { title: 'Checkpoint', body: `A mixed check on ${unit.title.toLowerCase()}: ${unit.lessons.map(lesson => lesson.grammar[0]).join(' · ')}. Get 75% to pass.` },
    vocabulary: lessons.flatMap(lesson => lesson.vocabulary.slice(0, 2)),
    challenges: renumber(mix, unit.checkpoint.id),
  };
  return { unit, lessons: [...lessons, checkpoint] };
});

// The final assessment draws a reply, a gap and a reading from every unit.
const last = builtUnits[builtUnits.length - 1];
if (last.unit.assessment) {
  const items = builtUnits.flatMap(({ lessons }, u) => {
    const challenge = lessons.filter(lesson => lesson.type === 'challenge');
    return [
      challenge[u % challenge.length].challenges.find(item => item.type === 'Choose the reply'),
      challenge[(u + 1) % challenge.length].challenges.find(item => item.type === 'Complete the sentence'),
      challenge[(u + 2) % challenge.length].challenges.find(item => item.type === 'Listen and arrange'),
      challenge.flatMap(lesson => lesson.challenges).find(item => item.type === 'Read and answer' && !/^[А-Яа-я]/.test(item.prompt)),
    ].filter(Boolean);
  });
  const { assessment } = last.unit;
  last.lessons.push({
    id: assessment.id, title: assessment.title, subtitle: assessment.subtitle, icon: '🏆', color: 'green', type: 'assessment', minPassPercent: 80,
    theory: { title: 'Final check', body: 'Twelve questions drawn from the whole A1 course: replies, sentences and short readings. Get 80% to pass.' },
    vocabulary: builtUnits.map(({ lessons }) => lessons[0].vocabulary[0]),
    challenges: renumber(items, assessment.id),
  });
}

const output = {
  schemaVersion: 1, id: course.id, title: course.title, sourceLanguage: 'en', targetLanguage: 'sr',
  version: course.version, status: 'published', contentStage: course.contentStage, sources: previous.sources,
  units: builtUnits.map(({ unit, lessons }) => ({ id: unit.id, level: 'A1', title: unit.title, subtitle: unit.subtitle, outcomes: unit.outcomes, lessons })),
};
const json = JSON.stringify(output, null, 2) + '\n';
writeFileSync('curriculum/serbian-en.v1.json', json);
writeFileSync('assets/course/serbian-en.v1.json', json);

// Review sheet for a native speaker.
const lines = ['# Serbian A1 — native-speaker review sheet', '', `Course version ${course.version}. Generated by scripts/build-course.mjs from curriculum/src/serbian-a1.mjs — edit the source, not this file.`, '', 'Please check grammar, naturalness and that the English matches. Wrong replies and distractors are meant to be wrong.', ''];
for (const unit of units) {
  lines.push(`## ${unit.title}`, '');
  for (const lesson of unit.lessons) {
    lines.push(`### ${lesson.title} (${lesson.id})`, '', `**Grammar note:** ${lesson.grammar[1].replace(/\n+/g, ' ')}`, '', '| Serbian | English |', '|---|---|');
    for (const word of words(lesson.words)) lines.push(`| ${word.latin} | ${word.english} |`);
    for (const [sr, en] of lesson.say) lines.push(`| ${sr} | ${en} |`);
    for (const [prompt, answer, others, en] of lesson.gaps || []) lines.push(`| ${prompt.replace('___', `**${answer}**`)} (wrong: ${others}) | ${en} |`);
    for (const [line, en, answer, wrong] of lesson.replies || []) lines.push(`| ${line} → **${answer}** (wrong: ${wrong.join(' / ')}) | ${en} |`);
    for (const item of lesson.read || []) lines.push(`| ${item.text.replace(/\n/g, ' / ')} | ${item.en} |`);
    lines.push('');
  }
}
writeFileSync('curriculum/REVIEW.md', lines.join('\n'));

const lessonCount = output.units.reduce((sum, unit) => sum + unit.lessons.length, 0);
const challengeCount = output.units.reduce((sum, unit) => sum + unit.lessons.reduce((n, lesson) => n + lesson.challenges.length, 0), 0);
console.log(`Built course v${course.version}: ${output.units.length} units, ${lessonCount} lessons, ${challengeCount} challenges.`);
}

import { pathToFileURL } from 'node:url';
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) build();
