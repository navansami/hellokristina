import { db, safe, method, send, token, publicUser, bcrypt } from '../../server/core.js';
import { DEFAULT_LOOK } from '../../server/avatar.js';
import { nameError, usernameError, emailError, passwordError, normalizeUsername } from '../../server/auth.js';

// GET ?username=x  -> { available, error? }  (live check while typing)
// POST { name, username, email, password, acceptedTerms, remember }
export default safe(async (req, res) => {
  if (!method(req, res, ['GET', 'POST'])) return;
  const database = await db();
  const users = database.collection('users');
  if (req.method === 'GET') {
    const username = normalizeUsername(req.query?.username);
    const error = usernameError(username);
    if (error) return send(res, 200, { available: false, error });
    const taken = await users.findOne({ username }, { projection: { _id: 1 } });
    return send(res, 200, taken ? { available: false, error: 'That username is taken' } : { available: true });
  }
  const { name, username: rawUsername, email, password, acceptedTerms, remember = true } = req.body || {};
  const username = normalizeUsername(rawUsername);
  const problems = [
    ['name', nameError(name)],
    ['username', usernameError(username)],
    ['email', emailError(email)],
    ['password', passwordError(password)],
    ['terms', acceptedTerms === true ? null : 'Please accept the terms to continue'],
  ].filter(([, error]) => error);
  if (problems.length) return send(res, 400, { error: problems[0][1], field: problems[0][0] });
  const normalized = email.toLowerCase().trim();
  if (await users.findOne({ email: normalized }, { projection: { _id: 1 } })) return send(res, 409, { error: 'This email is already registered. Try logging in.', field: 'email' });
  if (await users.findOne({ username }, { projection: { _id: 1 } })) return send(res, 409, { error: 'That username is taken', field: 'username' });
  const role = (process.env.ADMIN_EMAILS || '').split(',').map(x => x.trim().toLowerCase()).includes(normalized) ? 'admin' : 'learner';
  const now = new Date();
  const user = { name: name.trim().slice(0, 60), username, email: normalized, passwordHash: await bcrypt.hash(password, 12), avatar: { face: 'built', color: '#F6E7A8', look: { ...DEFAULT_LOOK } }, role, xp: 0, streak: 0, termsAcceptedAt: now, createdAt: now };
  const result = await users.insertOne(user); user._id = result.insertedId;
  await database.collection('progress').insertOne({ userId: user._id, courseId: 'serbian-en', completedLessons: [], learnedWords: [], lastActiveAt: now, dailyGoal: 15 });
  send(res, 201, { token: await token(user, remember === true), user: publicUser(user) });
});
