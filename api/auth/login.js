import { db, safe, method, send, token, publicUser, bcrypt } from '../../server/core.js';
export default safe(async (req, res) => {
  if (!method(req, res, ['POST'])) return;
  const { email, password, remember = true } = req.body || {};
  const user = await (await db()).collection('users').findOne({ email: (email || '').toLowerCase().trim() });
  if (!user || !(await bcrypt.compare(password || '', user.passwordHash))) return send(res, 401, { error: 'Email or password is incorrect' });
  send(res, 200, { token: await token(user, remember), user: publicUser(user) });
});
