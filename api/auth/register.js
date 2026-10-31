import { db, safe, method, send, token, publicUser, bcrypt } from '../../server/core.js';
export default safe(async (req, res) => {
  if (!method(req, res, ['POST'])) return;
  const { name, email, password, remember = true } = req.body || {};
  if (!name?.trim() || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email || '') || (password || '').length < 8) return send(res, 400, { error: 'Enter a name, valid email and password of at least 8 characters' });
  const database = await db(); const normalized = email.toLowerCase().trim();
  if (await database.collection('users').findOne({ email: normalized })) return send(res, 409, { error: 'This email is already registered' });
  const username = `${name.toLowerCase().replace(/[^a-z0-9]/g, '').slice(0, 14) || 'learner'}${Math.floor(Math.random() * 9000 + 1000)}`;
  const role = (process.env.ADMIN_EMAILS || '').split(',').map(x => x.trim().toLowerCase()).includes(normalized) ? 'admin' : 'learner';
  const user = { name: name.trim().slice(0, 60), username, email: normalized, passwordHash: await bcrypt.hash(password, 12), avatar: { face: 'built', color: '#F6E7A8', look: { skin: 6, body: 3, eye: 0, expression: 0, hair: 0, hairColor: 1, glasses: 0, glassesColor: 1, hat: 0, hatColor: 1, shirt: 4, background: 0 } }, role, xp: 0, streak: 0, createdAt: new Date() };
  const result = await database.collection('users').insertOne(user); user._id = result.insertedId;
  await database.collection('progress').insertOne({ userId: user._id, courseId: 'serbian-en', completedLessons: [], learnedWords: [], lastActiveAt: new Date(), dailyGoal: 15 });
  send(res, 201, { token: await token(user, remember), user: publicUser(user) });
});
