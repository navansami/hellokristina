import { safe, method, send, requireUser, db, publicUser } from '../../server/core.js';

const ranges = {
  skin: 15,
  body: 4,
  eye: 5,
  expression: 4,
  hair: 8,
  hairColor: 6,
  glasses: 3,
  glassesColor: 5,
  hat: 3,
  hatColor: 5,
  shirt: 9,
  background: 20
};

function readLook(raw) {
  if (!raw || typeof raw !== 'object') return null;
  const look = {};
  for (const [key, max] of Object.entries(ranges)) {
    const value = raw[key];
    if (!Number.isInteger(value) || value < 0 || value >= max) return null;
    look[key] = value;
  }
  return look;
}

export default safe(async (req, res) => {
  if (!method(req, res, ['PATCH'])) return;
  const user = await requireUser(req, res); if (!user) return;
  const color = String(req.body?.avatar?.color || '');
  if (!/^#[0-9A-Fa-f]{6}$/.test(color)) return send(res, 400, { error: 'Invalid avatar' });
  const look = readLook(req.body?.avatar?.look);
  const avatar = look
    ? { face: 'built', color, look }
    : (() => {
        const face = String(req.body?.avatar?.face || '');
        if (![...face].length || [...face].length > 8) return null;
        return { face, color };
      })();
  if (!avatar) return send(res, 400, { error: 'Invalid avatar' });
  await (await db()).collection('users').updateOne({ _id: user._id }, { $set: { avatar } });
  send(res, 200, { user: publicUser({ ...user, avatar }) });
});
