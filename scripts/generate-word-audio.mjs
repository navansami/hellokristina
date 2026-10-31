import { createHash } from 'node:crypto';
import { readFile, writeFile, mkdir, rename } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import OpenAI from 'openai';
const course=JSON.parse(await readFile('curriculum/serbian-en.v1.json','utf8'));
const normalized=text=>text.toLowerCase().replace(/[.,!?;:“”"()]/g,'').trim();
const available=new Map(), wanted=new Map();
for(const unit of course.units) for(const lesson of unit.lessons) {
  for(const word of lesson.vocabulary) if(!/\s/.test(word.latin.trim())) available.set(normalized(word.latin),word.audio);
  for(const q of lesson.challenges) {
    if(q.audioText && !/\s/.test(q.audioText.trim())) available.set(normalized(q.audioText),q.audio);
    if(q.answerLanguage===course.targetLanguage) for(const token of q.options) {
      const word=normalized(token);if(word && !/\s/.test(word)) wanted.set(word,token.replace(/[.,!?;:“”"()]/g,'').trim());
    }
  }
}
await mkdir('assets/audio/serbian',{recursive:true});
const manifest={};const pending=[];
for(const [word,input] of wanted) {
  const asset=available.get(word)||`audio/serbian/${createHash('sha256').update(input).digest('hex').slice(0,12)}.mp3`;
  manifest[word]=asset;
  if(!existsSync(join('assets',asset)))pending.push({asset,input});
}
console.log(`${wanted.size} selectable Serbian words; generating ${pending.length} missing clips.`);
if(pending.length && !process.env.OPENAI_API_KEY)throw new Error('OPENAI_API_KEY required for missing clips');
const client=new OpenAI({apiKey:process.env.OPENAI_API_KEY||'unused'});
let cursor=0;
async function worker(){while(cursor<pending.length){const {asset,input}=pending[cursor++];
  const result=await client.audio.speech.create({model:'gpt-4o-mini-tts',voice:'coral',input,
    instructions:'Speak only this Serbian word, with clear native Serbian pronunciation, warm teacher voice. Do not add any explanation.',response_format:'mp3',speed:.9});
  const bytes=Buffer.from(await result.arrayBuffer());if(bytes.length<1000)throw new Error(`Empty clip: ${asset}`);
  await writeFile(join('assets',asset)+'.tmp',bytes);await rename(join('assets',asset)+'.tmp',join('assets',asset));
  console.log(`${cursor}/${pending.length} ${asset}`);
}}
await Promise.all([worker(),worker(),worker()]);
await writeFile('assets/audio/serbian/word-index.json',JSON.stringify(manifest,null,2)+'\n');
console.log('Selectable-word audio index ready.');
