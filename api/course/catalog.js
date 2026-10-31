import { safe, method, send, db } from '../../server/core.js';
import { starterCourse } from '../../server/course.js';

export default safe(async (req, res) => {
  if (!method(req, res, ['GET'])) return;
  const id = req.query?.courseId || 'serbian-en';
  if (typeof id !== 'string' || !/^[a-z0-9-]{3,40}$/.test(id)) return send(res, 400, { error: 'Invalid course' });
  const collection = (await db()).collection('courses');
  if (id === starterCourse.id) {
    await collection.updateOne({ id }, { $setOnInsert: { ...starterCourse, seededAt: new Date() } }, { upsert: true });
  }
  const course = await collection.findOne({ id, status: 'published' }, { projection: { _id: 0, updatedBy: 0 } });
  if (!course && id !== starterCourse.id) return send(res, 404, { error: 'Course not found' });
  res.setHeader('Cache-Control', 'public, s-maxage=60, stale-while-revalidate=300');
  send(res, 200, { course: course || starterCourse });
});
