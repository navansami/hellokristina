import { practiceResult, validPracticeLength } from '../../server/practice-rounds.js';
import { sessionXp, segmentsEarned, claimRounds } from '../../server/xp.js';
import { updateMastery, recommendation } from '../../server/mastery.js';
import { safe, method, send, requireUser, db } from '../../server/core.js';
import { starterCourse, lessonPassed } from '../../server/course.js';
import { feedEvents, postFeedEvents } from '../../server/social.js';

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
  if (req.body?.testOut) return testOut(req, res, { user, database, collection, filter, lessons });
  if (req.body?.review) return review(req, res, { user, database, collection, filter });
  const { lessonId, roundIndex, answers = [] } = req.body || {};
  if (typeof lessonId !== 'string' || !/^[a-z0-9-]{2,80}$/.test(lessonId) || !Array.isArray(answers) || !answers.length || answers.length > 30 || answers.some(value => typeof value !== 'boolean')) return send(res, 400, { error: 'Invalid lesson result' });
  if (roundIndex !== undefined && (!Number.isInteger(roundIndex) || roundIndex < 0 || roundIndex > 4)) return send(res, 400, { error: 'Invalid practice round' });
  const lesson = lessons.find(item => item.id === lessonId);
  if (!lesson) return send(res, 400, { error: 'Lesson is not published' });
  if (!validPracticeLength(lesson, roundIndex, answers.length)) return send(res, 400, { error: 'Practice round needs 5 to 12 answers' });
  const passed = lessonPassed(lesson, answers);
  const prior = await collection.findOne(filter);
  const streak = nextStreak(user, prior);
  const key = `${lessonId}:${roundIndex ?? 'legacy'}`;
  const update = {
    $set: { lastActiveAt: new Date(), [`mastery.${lessonId}`]: updateMastery(prior?.mastery?.[lessonId], answers) },
    $inc: { [`attempts.${lessonId}`]: 1 },
  };
  // Strong sessions fill several ring segments; checkpoints fill all five.
  const segments = lesson.type === 'challenge' ? segmentsEarned(answers, passed) : (passed ? 5 : 0);
  const claimed = roundIndex === undefined ? [key] : claimRounds(prior?.completedRounds, lessonId, roundIndex, segments);
  if (passed) update.$addToSet = { completedRounds: { $each: claimed.length ? claimed : [key] }, learnedWords: { $each: lesson.vocabulary.map(word => word.latin) } };
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
  const xp = sessionXp(answers, passed, result.newRound);
  await database.collection('users').updateOne({ _id: user._id }, { $inc: { xp }, $set: { streak } });
  // Followers see finished lessons, level-ups and streak milestones.
  await postFeedEvents(database, user, feedEvents({
    before: { xp: user.xp || 0, streak: user.streak || 0 },
    after: { xp: (user.xp || 0) + xp, streak },
    lessonId: newlyCompleted ? lessonId : null,
  }), xp);
  send(res, 200, { xp, streak, passed, claimed, progress: await collection.findOne(filter, { projection: { _id: 0, userId: 0 } }) });
});

// Jump ahead: passing a test-out quiz (80%) completes every listed lesson.
async function testOut(req, res, { user, database, collection, filter, lessons }) {
  const { lessonIds, answers } = req.body;
  if (!Array.isArray(lessonIds) || !lessonIds.length || lessonIds.length > 120 || lessonIds.some(id => typeof id !== 'string') || !Array.isArray(answers) || answers.length < 8 || answers.length > 15 || answers.some(value => typeof value !== 'boolean')) return send(res, 400, { error: 'Invalid test-out result' });
  const published = new Set(lessons.map(lesson => lesson.id));
  if (lessonIds.some(id => !published.has(id))) return send(res, 400, { error: 'Lesson is not published' });
  const passed = answers.filter(Boolean).length * 100 >= 80 * answers.length;
  const xp = sessionXp(answers, passed, true);
  if (passed) {
    await collection.updateOne(filter, {
      $set: { lastActiveAt: new Date() },
      $addToSet: {
        completedLessons: { $each: lessonIds },
        completedRounds: { $each: lessonIds.flatMap(id => [0, 1, 2, 3, 4].map(i => `${id}:${i}`)) },
      },
    }, { upsert: true });
  }
  await database.collection('users').updateOne({ _id: user._id }, { $inc: { xp } });
  await postFeedEvents(database, user, feedEvents({
    before: { xp: user.xp || 0, streak: user.streak || 0 },
    after: { xp: (user.xp || 0) + xp, streak: user.streak || 0 },
  }), xp);
  send(res, 200, { xp, passed, progress: await collection.findOne(filter, { projection: { _id: 0, userId: 0 } }) });
}

function nextStreak(user, prior) {
  const today = new Date().toISOString().slice(0, 10);
  const yesterday = new Date(Date.now() - 86400000).toISOString().slice(0, 10);
  const last = prior?.lastActiveAt ? new Date(prior.lastActiveAt).toISOString().slice(0, 10) : null;
  return last === today ? user.streak || 1 : last === yesterday ? (user.streak || 0) + 1 : 1;
}

// Fix-your-mistakes sessions: passes at 60% and, like replays, earn half XP.
// They count towards the streak but don't touch lesson progress.
async function review(req, res, { user, database, collection, filter }) {
  const { answers } = req.body;
  if (!Array.isArray(answers) || answers.length < 3 || answers.length > 15 || answers.some(value => typeof value !== 'boolean')) return send(res, 400, { error: 'Invalid review result' });
  const passed = answers.filter(Boolean).length * 100 >= 60 * answers.length;
  const prior = await collection.findOne(filter);
  const streak = nextStreak(user, prior);
  await collection.updateOne(filter, { $set: { lastActiveAt: new Date() } }, { upsert: true });
  const xp = sessionXp(answers, passed, false);
  await database.collection('users').updateOne({ _id: user._id }, { $inc: { xp }, $set: { streak } });
  await postFeedEvents(database, user, feedEvents({
    before: { xp: user.xp || 0, streak: user.streak || 0 },
    after: { xp: (user.xp || 0) + xp, streak },
  }), xp);
  send(res, 200, { xp, streak, passed });
}
