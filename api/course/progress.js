import { practiceResult, validPracticeLength } from '../../server/practice-rounds.js';
import { updateMastery, recommendation } from '../../server/mastery.js';
import { safe, method, send, requireUser, db } from '../../server/core.js';
import { starterCourse, lessonPassed } from '../../server/course.js';

export default safe(async (req, res) => {
  if (!method(req, res, ['GET', 'POST'])) return;
  const user = await requireUser(req, res);
  if (!user) return;
  const courseId = req.method === 'GET' ? req.query?.courseId || 'serbian-en' : req.body?.courseId || 'serbian-en';
  if (typeof courseId !== 'string' || !/^[a-z0-9-]{3,40}$/.test(courseId)) return send(res, 400, { error: 'Invalid course' });
  const database = await db();
  const collection = database.collection('progress');
  const filter = { userId: user._id, courseId };
  const course = await database.collection('courses').findOne({ id: courseId, status: 'published' });
  const activeCourse = course || (courseId === starterCourse.id ? starterCourse : null);
  const lessons = activeCourse?.units.flatMap(unit => unit.lessons) || [];
  if (req.method === 'GET') {
    const progress = await collection.findOne(filter, { projection: { _id: 0, userId: 0 } });
    return send(res, 200, { progress, recommendation: lessons.length ? recommendation(progress, lessons.map(lesson => lesson.id)) : null });
  }
  const { lessonId, roundIndex, answers = [] } = req.body || {};
  if (typeof lessonId !== 'string' || !/^[a-z0-9-]{2,80}$/.test(lessonId) || !Array.isArray(answers) || !answers.length || answers.length > 30 || answers.some(value => typeof value !== 'boolean')) return send(res, 400, { error: 'Invalid lesson result' });
  if (roundIndex !== undefined && (!Number.isInteger(roundIndex) || roundIndex < 0 || roundIndex > 4)) return send(res, 400, { error: 'Invalid practice round' });
  const lesson = lessons.find(item => item.id === lessonId);
  if (!lesson) return send(res, 400, { error: 'Lesson is not published' });
  if (!validPracticeLength(lesson, roundIndex, answers.length)) return send(res, 400, { error: 'Practice round needs 8 to 12 answers' });
  const passed = lessonPassed(lesson, answers);
  const prior = await collection.findOne(filter);
  const today = new Date().toISOString().slice(0, 10);
  const yesterday = new Date(Date.now() - 86400000).toISOString().slice(0, 10);
  const last = prior?.lastActiveAt ? new Date(prior.lastActiveAt).toISOString().slice(0, 10) : null;
  const streak = last === today ? user.streak || 1 : last === yesterday ? (user.streak || 0) + 1 : 1;
  const key = `${lessonId}:${roundIndex ?? 'legacy'}`;
  const update = {
    $set: { lastActiveAt: new Date(), [`mastery.${lessonId}`]: updateMastery(prior?.mastery?.[lessonId], answers) },
    $inc: { [`attempts.${lessonId}`]: 1 },
  };
  if (passed) update.$addToSet = { completedRounds: key, learnedWords: { $each: lesson.vocabulary.map(word => word.latin) } };
  // Return the state immediately before the atomic insertion to claim XP once.
  const previous = await collection.findOneAndUpdate(filter, update, { upsert: true, returnDocument: 'before' });
  const result = practiceResult(previous, lessonId, roundIndex, passed);
  const latest = await collection.findOne(filter);
  const complete = practiceResult(latest, lessonId, roundIndex, passed).circleComplete;
  let newlyCompleted = false;
  if (complete) {
    const completion = await collection.updateOne({ ...filter, completedLessons: { $ne: lessonId } }, { $addToSet: { completedLessons: lessonId } });
    newlyCompleted = completion.modifiedCount === 1;
  }
  const xp = passed && result.newRound ? Math.min(30, 10 + answers.filter(Boolean).length * 5) : 0;
  await database.collection('users').updateOne({ _id: user._id }, { $inc: { xp }, $set: { streak } });
  if (newlyCompleted) await database.collection('feed').insertOne({ actorId: user._id, actorName: user.name, actorAvatar: user.avatar, type: 'lesson', lessonId, xp, likes: [], createdAt: new Date() });
  send(res, 200, { xp, streak, passed, progress: await collection.findOne(filter, { projection: { _id: 0, userId: 0 } }) });
});
