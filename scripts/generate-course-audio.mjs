import { mkdir, rename, writeFile, readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import OpenAI from 'openai';
import { starterCourse } from '../server/course.js';

if (!process.env.OPENAI_API_KEY) throw new Error('OPENAI_API_KEY is required');
const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
const clips = new Map();
for (const unit of starterCourse.units) for (const lesson of unit.lessons) {
  for (const word of lesson.vocabulary) clips.set(word.audio, word.latin);
  for (const challenge of lesson.challenges) clips.set(challenge.audio, challenge.audioText);
}
const pending = [...clips].filter(([asset]) => !existsSync(join('assets', asset)));
console.log(`Generating ${pending.length} of ${clips.size} Serbian clips.`);
await mkdir('assets/audio/serbian', { recursive: true });
let index = 0;
async function worker() {
  while (index < pending.length) {
    const [asset, input] = pending[index++];
    const destination = join('assets', asset);
    let lastError;
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        const response = await client.audio.speech.create({
          model: 'gpt-4o-mini-tts', voice: 'coral', input,
          instructions: 'Speak Serbian with a natural Serbian accent. Clear, warm, playful teacher voice. Give only the Serbian text. Pause briefly at punctuation.',
          response_format: 'mp3', speed: 0.9,
        });
        const bytes = Buffer.from(await response.arrayBuffer());
        if (bytes.length < 1000) throw new Error(`Audio too small for ${asset}`);
        const temp = `${destination}.tmp`;
        await writeFile(temp, bytes);
        await rename(temp, destination);
        console.log(`${index}/${pending.length} ${asset} ${bytes.length} bytes`);
        lastError = null;
        break;
      } catch (error) {
        lastError = error;
        if (attempt < 2) await new Promise(resolve => setTimeout(resolve, 1000 * (attempt + 1)));
      }
    }
    if (lastError) throw new Error(`Could not generate ${asset}: ${lastError.message}`);
  }
}
await Promise.all([worker(), worker()]);
for (const asset of clips.keys()) {
  const bytes = await readFile(join('assets', asset));
  if (bytes.length < 1000) throw new Error(`Invalid audio: ${asset}`);
}
console.log('All Serbian audio clips ready.');
