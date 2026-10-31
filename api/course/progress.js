import { updateMastery, recommendation } from '../../server/mastery.js';
import { safe, method, send, requireUser, db } from '../../server/core.js';
export default safe(async (req, res) => {
  if (!method(req, res, ['GET', 'POST'])) return;
  const user = await requireUser(req, res); if (!user) return;
  const courseId = req.method === 'GET' ? req.query?.courseId || 'serbian-en' : req.body?.courseId || 'serbian-en';
  if (typeof courseId !== 'string' || !/^[a-z0-9-]{3,40}$/.test(courseId)) return send(res, 400, { error: 'Invalid course' });
  const database = await db(); const collection = database.collection('progress'); const filter = { userId: user._id, courseId };
  if (req.method === 'GET') { const progress = await collection.findOne(filter, { projection: { _id: 0, userId: 0 } }); return send(res, 200, { progress, recommendation: courseId === 'serbian-en' ? recommendation(progress, ['hello','introductions','polite','numbers','coffee','family']) : null }); }
  const { lessonId, words = [], answers = [] } = req.body || {};
  if (typeof lessonId !== 'string' || !/^[a-z0-9-]{2,80}$/.test(lessonId) || !Array.isArray(words) || !Array.isArray(answers) || answers.length < 1 || answers.length > 30 || answers.some(x => typeof x !== 'boolean')) return send(res, 400, { error: 'Invalid lesson result' });
  const starterIds = ['hello','introductions','polite','numbers','coffee','family'];
  const course = await database.collection('courses').findOne({ id: courseId });
  const publishedIds = (course?.units || []).flatMap(unit => (unit.lessons || []).filter(lesson => lesson.published).map(lesson => lesson.id));
  if (!(courseId === 'serbian-en' && starterIds.includes(lessonId)) && !publishedIds.includes(lessonId)) return send(res, 400, { error: 'Lesson is not published' });
  const prior = await collection.findOne(filter);
  const newLesson = !prior?.completedLessons?.includes(lessonId);
  const xp = newLesson ? Math.min(30, 10 + answers.filter(Boolean).length * 5) : 0;
  const today = new Date().toISOString().slice(0, 10); const yesterday = new Date(Date.now() - 86400000).toISOString().slice(0, 10);
  const last = prior?.lastActiveAt ? new Date(prior.lastActiveAt).toISOString().slice(0, 10) : null;
  const streak = last === today ? user.streak || 1 : last === yesterday ? (user.streak || 0) + 1 : 1;
  const mastery = updateMastery(prior?.mastery?.[lessonId], answers);
  await collection.updateOne(filter, { $addToSet: { completedLessons: lessonId, learnedWords: { $each: words.filter(x => typeof x === 'string').slice(0, 30) } }, $set: { lastActiveAt: new Date(), [`mastery.${lessonId}`]: mastery } }, { upsert: true });
  await database.collection('users').updateOne({ _id: user._id }, { $inc: { xp }, $set: { streak } });
  if (newLesson) await database.collection('feed').insertOne({ actorId: user._id, actorName: user.name, actorAvatar: user.avatar, type: 'lesson', lessonId, xp, likes: [], createdAt: new Date() });
  send(res, 200, { xp, streak, progress: await collection.findOne(filter, { projection: { _id: 0, userId: 0 } }) });
});
