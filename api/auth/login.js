import { db, safe, method, send, token, publicUser, bcrypt } from '../../server/core.js';
import { emailError, passwordError, normalizeUsername, newResetToken, hashResetToken, sendResetEmail, siteOrigin, RESET_MINUTES } from '../../server/auth.js';

// POST { identifier | email, password, remember }      -> log in
// POST { action: 'forgot', email }                     -> email a reset link
// POST { action: 'reset', token, password }            -> set a new password
// (Kept in one function: the Vercel Hobby plan allows 12.)
export default safe(async (req, res) => {
  if (!method(req, res, ['POST'])) return;
  const body = req.body || {};
  if (body.action === 'forgot') return forgot(req, res, body);
  if (body.action === 'reset') return reset(res, body);
  const identifier = String(body.identifier ?? body.email ?? '').trim();
  const users = (await db()).collection('users');
  const user = identifier.includes('@')
    ? await users.findOne({ email: identifier.toLowerCase() })
    : await users.findOne({ username: normalizeUsername(identifier) });
  if (!user || !(await bcrypt.compare(String(body.password ?? ''), user.passwordHash))) return send(res, 401, { error: 'That email, username or password isn’t right' });
  send(res, 200, { token: await token(user, body.remember === true), user: publicUser(user) });
});

async function forgot(req, res, { email }) {
  if (emailError(email)) return send(res, 400, { error: 'Enter a valid email address', field: 'email' });
  if (!process.env.RESEND_API_KEY || !process.env.MAIL_FROM) return send(res, 503, { error: 'Password reset emails aren’t set up yet. Please contact support.' });
  const database = await db();
  const user = await database.collection('users').findOne({ email: email.toLowerCase().trim() });
  // Always answer the same way so the form can't reveal who has an account.
  const done = () => send(res, 200, { ok: true });
  if (!user) return done();
  const resets = database.collection('password_resets');
  // One email a minute per account is plenty.
  if (await resets.findOne({ userId: user._id, createdAt: { $gt: new Date(Date.now() - 60_000) } })) return done();
  const { token: secret, hash } = newResetToken();
  await resets.deleteMany({ userId: user._id });
  await resets.insertOne({ userId: user._id, hash, createdAt: new Date(), expiresAt: new Date(Date.now() + RESET_MINUTES * 60_000) });
  await sendResetEmail({ to: user.email, name: user.name, link: `${siteOrigin(req)}/?reset=${secret}` });
  done();
}

async function reset(res, { token: secret, password }) {
  const problem = passwordError(password);
  if (problem) return send(res, 400, { error: problem, field: 'password' });
  if (typeof secret !== 'string' || secret.length < 20) return send(res, 400, { error: 'This reset link isn’t valid. Ask for a new one.' });
  const database = await db();
  const resets = database.collection('password_resets');
  const entry = await resets.findOneAndDelete({ hash: hashResetToken(secret) });
  if (!entry || entry.expiresAt < new Date()) return send(res, 400, { error: 'This reset link has expired. Ask for a new one.' });
  // Changing the password also signs out every existing session.
  await database.collection('users').updateOne({ _id: entry.userId }, { $set: { passwordHash: await bcrypt.hash(password, 12), passwordChangedAt: new Date() } });
  send(res, 200, { ok: true });
}
