import OpenAI from 'openai';
import { safe, method, send, requireUser, db } from '../../server/core.js';
export default safe(async (req, res) => {
  if (!method(req, res, ['POST'])) return;
  const user = await requireUser(req, res); if (!user) return;
  if (!process.env.OPENAI_API_KEY) return send(res, 503, { error: 'AI tutor is not configured yet' });
  const message = String(req.body?.message || '').trim();
  if (!message || message.length > 1000) return send(res, 400, { error: 'Write a message under 1,000 characters' });
  const database = await db();
  const recent = await database.collection('chat').find({ userId: user._id }).sort({ createdAt: -1 }).limit(12).toArray();
  const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  const response = await client.responses.create({ model: process.env.OPENAI_MODEL || 'gpt-4o-mini', instructions: 'You are Kristina, a warm, sassy Serbian tutor for English speakers. Teach accurate Serbian, using Latin and Cyrillic when helpful. Keep replies short, encouraging, and gently cheeky. Correct mistakes kindly. Ask one follow-up practice question. Never insult the learner.', input: [...recent.reverse().flatMap(x => [{ role: 'user', content: x.message }, { role: 'assistant', content: x.reply }]), { role: 'user', content: message }] });
  const reply = response.output_text || 'Try that again, superstar.';
  await database.collection('chat').insertOne({ userId: user._id, message, reply, createdAt: new Date() });
  send(res, 200, { reply });
});
