import { safe, method, send, requireAdmin, db } from '../../server/core.js';
import { validateCourse } from '../../server/course.js';

export default safe(async (req, res) => {
  if (!method(req, res, ['GET', 'POST', 'PATCH'])) return;
  const admin = await requireAdmin(req, res);
  if (!admin) return;
  const database = await db();
  const published = database.collection('courses');
  const drafts = database.collection('course_drafts');
  if (req.method === 'GET') {
    const [courses, savedDrafts] = await Promise.all([
      published.find({}, { projection: { _id: 0 } }).toArray(),
      drafts.find({}, { projection: { _id: 0 } }).toArray(),
    ]);
    return send(res, 200, { courses, drafts: savedDrafts });
  }
  if (req.method === 'POST') {
    let course;
    try { course = validateCourse({ ...req.body?.course, status: 'draft' }); }
    catch (error) { return send(res, 400, { error: error.message }); }
    await drafts.updateOne({ id: course.id }, { $set: {
      ...course, updatedAt: new Date(), updatedBy: String(admin._id),
    } }, { upsert: true });
    return send(res, 200, { course, message: 'Draft saved for review' });
  }
  const { id, reviewed } = req.body || {};
  if (typeof id !== 'string' || reviewed !== true) return send(res, 400, { error: 'Course ID and human review confirmation required' });
  const draft = await drafts.findOne({ id });
  if (!draft) return send(res, 404, { error: 'Draft not found' });
  let course;
  try { course = validateCourse({ ...draft, status: 'published' }); }
  catch (error) { return send(res, 400, { error: error.message }); }
  const previous = await published.findOne({ id });
  const version = (previous?.version || 0) + 1;
  if (previous) {
    const { _id, ...archived } = previous;
    await database.collection('course_revisions').insertOne({ ...archived, archivedAt: new Date() });
  }
  const result = { ...course, version, updatedAt: new Date(), updatedBy: String(admin._id) };
  await published.updateOne({ id }, { $set: result }, { upsert: true });
  await drafts.deleteOne({ id });
  send(res, 200, { course: result });
});
