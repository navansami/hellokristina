import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
const course=JSON.parse(readFileSync('curriculum/serbian-en.v1.json','utf8'));
const index=JSON.parse(readFileSync('assets/audio/serbian/word-index.json','utf8'));
const key=text=>text.toLowerCase().replace(/[.,!?;:“”"()]/g,'').trim();
const wanted=new Set();
for(const unit of course.units)for(const lesson of unit.lessons)for(const question of lesson.challenges) {
  if(question.answerLanguage===course.targetLanguage)for(const option of question.options)wanted.add(key(option));
}
for(const word of wanted){
  assert(index[word],`Missing selected-word audio: ${word}`);
  assert(/^audio\/serbian\/[a-f0-9]{12}\.mp3$/.test(index[word]));
  const bytes=readFileSync(`assets/${index[word]}`);assert(bytes.length>1000);
  assert(bytes[0]===0xff||bytes.subarray(0,3).toString()==='ID3');
}
for(const name of ['tap','correct','retry','streak','hot_streak','complete','perfect']) {
  const bytes=readFileSync(`assets/audio/effects/${name}.wav`);
  assert.equal(bytes.subarray(0,4).toString(),'RIFF');assert.equal(bytes.subarray(8,12).toString(),'WAVE');
  const duration=(bytes.length-44)/bytes.readUInt32LE(28);assert(duration>.03&&duration<1.5);
  let peak=0;for(let i=44;i<bytes.length;i+=2)peak=Math.max(peak,Math.abs(bytes.readInt16LE(i))/32767);
  assert(peak>.01&&peak<.6,`Check effect volume: ${name}`);
}
console.log(`All ${wanted.size} selectable Serbian words have audio; seven short feedback sounds have valid duration and levels.`);
