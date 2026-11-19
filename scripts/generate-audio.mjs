// Generates every Serbian clip the course needs, in each tutor's voice, and
// normalises loudness so clips play clearly on phones.
//
//   node --env-file=.env scripts/generate-audio.mjs           generate missing clips
//   node scripts/generate-audio.mjs --dry-run                 count only, no API calls
//   node --env-file=.env scripts/generate-audio.mjs --sample  six sample clips to tmp/
//
// Kristina (default) speaks every clip; Miloš and Zara speak the lesson
// clips too, so the voice always matches the tutor on screen. Word tiles use
// Kristina's voice. Requires OPENAI_API_KEY and ffmpeg (FFMPEG env var, or
// `pip install imageio-ffmpeg`). Costs money: run only when the course changes.
import { createHash } from 'node:crypto';
import { execFileSync, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, readdirSync, rmSync, writeFileSync, renameSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

const MODEL = 'gpt-4o-mini-tts';
const VERSION = 2; // bump to regenerate everything
const args = new Set(process.argv.slice(2));
const dryRun = args.has('--dry-run');
const sample = args.has('--sample');

export const voices = [
  { folder: '', name: 'Kristina', voice: 'marin', persona: 'Kristina, a warm, cheerful woman in her late twenties from Belgrade who teaches Serbian to friends' },
  { folder: 'milos/', name: 'Miloš', voice: 'cedar', persona: 'Miloš, a friendly, easy-going man in his early thirties from Novi Sad who loves chatting with learners' },
  { folder: 'zara/', name: 'Zara', voice: 'coral', persona: 'Zara, a bright, upbeat young woman from Belgrade with an energetic, playful way of speaking' },
];

const instructions = (persona, short) => [
  `Voice: ${persona}.`,
  'Language: Serbian, standard ekavian with a native Belgrade accent and natural Serbian stress. Never use an English accent.',
  'Tone: warm, friendly and encouraging, with a real smile in the voice. Lively, natural intonation, as if talking to a friend. Never flat, never robotic.',
  'Pace: relaxed and clear, every syllable easy to hear, but not slowed down.',
  short ? 'This is a single word or short phrase: say it once, clearly, with natural intonation.' : 'Pause naturally at punctuation and line breaks.',
  'Say exactly the given text and nothing else.',
].join(' ');

const course = JSON.parse(readFileSync('curriculum/serbian-en.v1.json', 'utf8'));
const hash = text => createHash('sha256').update(text).digest('hex').slice(0, 12);
const wordKey = text => text.toLowerCase().replace(/[.,!?;:“”"()„]/g, '').trim();

// Lesson clips: vocabulary and every challenge's audio, in all three voices.
const lessonClips = new Map();
for (const unit of course.units) for (const lesson of unit.lessons) {
  for (const word of lesson.vocabulary) lessonClips.set(word.audio, word.latin);
  for (const item of lesson.challenges) if (item.audio) lessonClips.set(item.audio, item.audioText);
}
// Selectable Serbian answers: single word tiles and whole reply options.
const textToAsset = new Map([...lessonClips].map(([asset, text]) => [wordKey(text), asset]));
const wordIndex = {};
const wordClips = new Map();
for (const unit of course.units) for (const lesson of unit.lessons) for (const item of lesson.challenges) {
  if (item.answerLanguage !== course.targetLanguage) continue;
  const choices = item.type === 'Choose the reply' ? item.options : item.options.flatMap(option => option.split(/\s+/));
  for (const choice of choices) {
    const key = wordKey(choice);
    if (!key) continue;
    const spoken = choice.replace(/[“”"„]/g, '').trim();
    const asset = textToAsset.get(key) || `audio/serbian/${hash(spoken)}.mp3`;
    wordIndex[key] = asset;
    if (!lessonClips.has(asset)) wordClips.set(asset, spoken);
  }
}

const jobs = [];
for (const [asset, text] of lessonClips) for (const voice of voices) {
  jobs.push({ path: asset.replace('audio/serbian/', `audio/serbian/${voice.folder}`), text, voice, short: !/\s/.test(text.trim()) || text.length < 14 });
}
for (const [asset, text] of wordClips) jobs.push({ path: asset, text, voice: voices[0], short: true });

const manifestPath = 'curriculum/audio-manifest.json';
const manifest = existsSync(manifestPath) ? JSON.parse(readFileSync(manifestPath, 'utf8')) : {};
const signature = job => `${VERSION}|${MODEL}|${job.voice.voice}|${job.text}`;
const pending = jobs.filter(job => manifest[job.path] !== signature(job) || !existsSync(join('assets', job.path)));
const characters = pending.reduce((sum, job) => sum + job.text.length, 0);
console.log(`${jobs.length} clips (${lessonClips.size} lesson clips × ${voices.length} voices + ${wordClips.size} answer clips); ${pending.length} to generate, ${characters} characters.`);
// About 15 characters of Serbian per second of speech, about $0.015 per minute.
console.log(`Estimated cost: about $${((characters / 15 / 60) * 0.015 + characters / 4 * 0.6e-6).toFixed(2)}.`);
if (dryRun) process.exit(0);

function ffmpegPath() {
  if (process.env.FFMPEG) return process.env.FFMPEG;
  try {
    return execFileSync('python', ['-c', 'import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())'], { encoding: 'utf8' }).trim();
  } catch {
    return 'ffmpeg';
  }
}
const ffmpeg = ffmpegPath();
const trim = 'silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,areverse,silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.12,areverse';
// Gentle compression evens out peaks so every voice can reach the same loudness.
const shape = `${trim},highpass=f=70,acompressor=threshold=-22dB:ratio=3:attack=4:release=90:makeup=3,alimiter=limit=0.8:level=false`;

/// Trim silence, then two-pass loudness normalisation to -16 LUFS with a
/// -1.5 dBTP ceiling: loud and clear on phone speakers without clipping.
function loudnorm(input, output) {
  const filter = `${shape},apad=pad_dur=0.6,loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json`;
  const result = runFfmpeg(['-hide_banner', '-nostats', '-i', input, '-af', filter, '-f', 'null', '-']);
  const json = JSON.parse(result.slice(result.lastIndexOf('{'), result.lastIndexOf('}') + 1));
  // Exact gain to -16 LUFS, then a limiter keeps peaks under -1.5 dBFS.
  const gain = (-16 - Number(json.input_i)).toFixed(2);
  const second = `${shape},volume=${gain}dB,alimiter=limit=0.84:attack=2:release=40:level=false,aresample=24000,adelay=60|60,apad=pad_dur=0.12`;
  runFfmpeg(['-hide_banner', '-nostats', '-y', '-i', input, '-af', second, '-ac', '1', '-ar', '24000', '-c:a', 'libmp3lame', '-b:a', '64k', output]);
}
function runFfmpeg(argv) {
  // ffmpeg reports on stderr; spawnSync keeps it even on success.
  const run = spawnSync(ffmpeg, argv, { encoding: 'utf8' });
  if (run.status !== 0) throw new Error(`ffmpeg failed: ${run.stderr.slice(-400)}`);
  return run.stderr;
}

const work = join(tmpdir(), 'hk-audio');
mkdirSync(work, { recursive: true });

async function speak(job) {
  const response = await fetch('https://api.openai.com/v1/audio/speech', {
    method: 'POST',
    headers: { Authorization: `Bearer ${process.env.OPENAI_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: MODEL, voice: job.voice.voice, input: job.text, instructions: instructions(job.voice.persona, job.short), response_format: 'wav', speed: 1.0 }),
  });
  if (!response.ok) {
    const error = new Error(`${response.status} ${(await response.text()).slice(0, 200)}`);
    error.status = response.status;
    throw error;
  }
  return Buffer.from(await response.arrayBuffer());
}

async function produce(job, destination) {
  let lastError;
  for (let attempt = 0; attempt < 5; attempt++) {
    try {
      const raw = join(work, `${hash(job.path)}.wav`);
      writeFileSync(raw, await speak(job));
      const temp = `${destination}.tmp.mp3`;
      loudnorm(raw, temp);
      rmSync(raw, { force: true });
      if (readFileSync(temp).length < 1500) throw new Error('clip too small');
      renameSync(temp, destination);
      return;
    } catch (error) {
      lastError = error;
      const wait = error.status === 429 ? 4000 * (attempt + 1) : 1000 * (attempt + 1);
      await new Promise(resolve => setTimeout(resolve, wait));
    }
  }
  throw new Error(`Could not generate ${job.path} (${job.text}): ${lastError.message}`);
}

if (!process.env.OPENAI_API_KEY) throw new Error('OPENAI_API_KEY is required (node --env-file=.env ...)');

if (sample) {
  mkdirSync('tmp/voice-samples', { recursive: true });
  const lines = ['Zdravo! Kako si?', 'Jednu kafu, molim vas.'];
  for (const voice of voices) for (const [i, text] of lines.entries()) {
    const file = `tmp/voice-samples/${voice.name.replace('š', 's')}-${i + 1}.mp3`;
    await produce({ path: file, text, voice, short: false }, file);
    console.log(file);
  }
  process.exit(0);
}

for (const voice of voices) mkdirSync(join('assets/audio/serbian', voice.folder), { recursive: true });
let cursor = 0, done = 0;
const saveManifest = () => writeFileSync(manifestPath, JSON.stringify(Object.fromEntries(Object.entries(manifest).sort()), null, 1) + '\n');
async function worker() {
  while (cursor < pending.length) {
    const job = pending[cursor++];
    await produce(job, join('assets', job.path));
    manifest[job.path] = signature(job);
    if (++done % 25 === 0) { saveManifest(); console.log(`${done}/${pending.length}`); }
  }
}
await Promise.all(Array.from({ length: 8 }, worker));
saveManifest();

// Remove clips the course no longer uses, and write the answer index.
const wanted = new Set(jobs.map(job => job.path));
let removed = 0;
for (const voice of voices) {
  const folder = join('assets/audio/serbian', voice.folder);
  for (const file of readdirSync(folder)) {
    if (!file.endsWith('.mp3')) continue;
    const path = `audio/serbian/${voice.folder}${file}`;
    if (!wanted.has(path)) { rmSync(join('assets', path)); delete manifest[path]; removed++; }
  }
}
saveManifest();
writeFileSync('assets/audio/serbian/word-index.json', JSON.stringify(Object.fromEntries(Object.entries(wordIndex).sort()), null, 2) + '\n');
console.log(`Generated ${done} clips, removed ${removed} unused clips. Audio ready.`);
