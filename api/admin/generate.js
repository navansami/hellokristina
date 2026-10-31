import OpenAI from 'openai';
import { safe, method, send, requireAdmin } from '../../server/core.js';
export default safe(async (req, res) => {
  if (!method(req, res, ['POST'])) return;
  if (!await requireAdmin(req, res)) return;
  if (!process.env.OPENAI_API_KEY) return send(res, 503, { error: 'OPENAI_API_KEY is not configured' });
  const { level, topic, objectives } = req.body || {};
  if (!['A1','A2','B1','B2','C1','C2'].includes(level) || !topic || String(topic).length > 100) return send(res, 400, { error: 'Choose a CEFR level and topic' });
  const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  const response = await client.chat.completions.create({ model: 'gpt-4o-mini', temperature: 0.6, response_format: { type: 'json_object' }, messages: [
    { role: 'system', content: 'Create accurate Serbian lessons for English speakers. Return JSON with title, level, objectives (array), vocabulary (array of {sr, en, transliteration}), explanation, and challenges (array of {type, prompt, options, answer, explanation}). Include 8 varied challenges. Use both Serbian Latin and Cyrillic where useful. Do not invent grammar rules. Content is a draft for human review.' },
    { role: 'user', content: JSON.stringify({ level, topic, objectives }) }
  ] });
  send(res, 200, { draft: JSON.parse(response.choices[0].message.content) });
});
