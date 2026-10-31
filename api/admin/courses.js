import { safe, method, send, requireAdmin, db } from '../../server/core.js';
export default safe(async (req, res) => {
  if (!method(req, res, ['GET', 'POST'])) return;
  const admin = await requireAdmin(req, res); if (!admin) return;
  const collection = (await db()).collection('courses');
  if (req.method === 'GET') return send(res, 200, { courses: await collection.find({}, { projection: { _id: 0 } }).toArray() });
  const { id, title, sourceLanguage, targetLanguage, units } = req.body || {};
  if (!/^[a-z0-9-]{3,40}$/.test(id || '') || !title || !sourceLanguage || !targetLanguage || !Array.isArray(units)) return send(res, 400, { error: 'Invalid course' });
  const course = { id, title, sourceLanguage, targetLanguage, units, updatedAt: new Date(), updatedBy: String(admin._id) };
  await collection.updateOne({ id }, { $set: course }, { upsert: true }); send(res, 200, { course });
});
