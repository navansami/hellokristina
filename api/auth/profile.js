import { safe, method, send, requireUser, db, publicUser } from '../../server/core.js';
export default safe(async (req, res) => {
  if (!method(req, res, ['PATCH'])) return;
  const user = await requireUser(req, res); if (!user) return;
  const face = String(req.body?.avatar?.face || '');
  const color = String(req.body?.avatar?.color || '');
  if (![...face].length || [...face].length > 4 || !/^#[0-9A-Fa-f]{6}$/.test(color)) return send(res, 400, { error: 'Invalid avatar' });
  await (await db()).collection('users').updateOne({ _id: user._id }, { $set: { avatar: { face, color } } });
  send(res, 200, { user: publicUser({ ...user, avatar: { face, color } }) });
});
