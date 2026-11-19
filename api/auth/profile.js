import { safe, method, send, requireUser, db, publicUser, token, bcrypt } from '../../server/core.js';
import { nameError, usernameError, emailError, passwordError, normalizeUsername } from '../../server/auth.js';
import { readLook } from '../../server/avatar.js';

// PATCH { avatar }                                   -> change the avatar
// PATCH { details: { name, username } }               -> rename
// PATCH { email, currentPassword }                    -> change email
// PATCH { password: { current, next }, remember }     -> change password
// PATCH { action: 'signOutEverywhere', remember }     -> end other sessions
// DELETE { currentPassword }                          -> delete the account
// Password changes and "sign out everywhere" end every other session, so
// they return a fresh token for this device.
export default safe(async (req, res) => {
  if (!method(req, res, ['PATCH', 'DELETE'])) return;
  const user = await requireUser(req, res); if (!user) return;
  const database = await db();
  const users = database.collection('users');
  const body = req.body || {};
  const checkPassword = async raw => {
    const full = await users.findOne({ _id: user._id }, { projection: { passwordHash: 1 } });
    return Boolean(full && await bcrypt.compare(String(raw ?? ''), full.passwordHash));
  };
  const wrongPassword = () => send(res, 403, { error: 'That password isn’t right', field: 'currentPassword' });

  if (req.method === 'DELETE') {
    if (!await checkPassword(body.currentPassword)) return wrongPassword();
    await deleteAccount(database, user._id);
    return send(res, 200, { ok: true });
  }

  if (body.avatar) return updateAvatar(res, users, user, body.avatar);

  if (body.details) {
    const name = String(body.details.name ?? '').trim();
    const username = normalizeUsername(body.details.username);
    const problem = nameError(name) ? ['name', nameError(name)] : usernameError(username) ? ['username', usernameError(username)] : null;
    if (problem) return send(res, 400, { error: problem[1], field: problem[0] });
    if (username !== user.username && await users.findOne({ username }, { projection: { _id: 1 } })) return send(res, 409, { error: 'That username is taken', field: 'username' });
    await users.updateOne({ _id: user._id }, { $set: { name: name.slice(0, 60), username } });
    return send(res, 200, { user: publicUser({ ...user, name: name.slice(0, 60), username }) });
  }

  if (body.email !== undefined) {
    const email = String(body.email).toLowerCase().trim();
    if (emailError(email)) return send(res, 400, { error: emailError(email), field: 'email' });
    if (!await checkPassword(body.currentPassword)) return wrongPassword();
    if (email !== user.email && await users.findOne({ email }, { projection: { _id: 1 } })) return send(res, 409, { error: 'Another account already uses this email', field: 'email' });
    await users.updateOne({ _id: user._id }, { $set: { email } });
    return send(res, 200, { user: publicUser({ ...user, email }) });
  }

  if (body.password) {
    const next = String(body.password.next ?? '');
    if (passwordError(next)) return send(res, 400, { error: passwordError(next), field: 'newPassword' });
    if (!await checkPassword(body.password.current)) return wrongPassword();
    const now = new Date();
    await users.updateOne({ _id: user._id }, { $set: { passwordHash: await bcrypt.hash(next, 12), passwordChangedAt: now, sessionsValidAfter: now } });
    await database.collection('password_resets').deleteMany({ userId: user._id });
    return send(res, 200, { token: await freshToken(user, body.remember), user: publicUser(user) });
  }

  if (body.action === 'signOutEverywhere') {
    await users.updateOne({ _id: user._id }, { $set: { sessionsValidAfter: new Date() } });
    return send(res, 200, { token: await freshToken(user, body.remember), user: publicUser(user) });
  }

  send(res, 400, { error: 'Nothing to change' });
});

// Issued at the cut-off; userFrom's one-second tolerance keeps it valid.
function freshToken(user, remember) {
  return token(user, remember === true);
}

async function updateAvatar(res, users, user, raw) {
  const color = String(raw?.color || '');
  if (!/^#[0-9A-Fa-f]{6}$/.test(color)) return send(res, 400, { error: 'Invalid avatar' });
  const look = readLook(raw?.look);
  const avatar = look
    ? { face: 'built', color, look }
    : (() => {
        const face = String(raw?.face || '');
        if (![...face].length || [...face].length > 8) return null;
        return { face, color };
      })();
  if (!avatar) return send(res, 400, { error: 'Invalid avatar' });
  await users.updateOne({ _id: user._id }, { $set: { avatar } });
  send(res, 200, { user: publicUser({ ...user, avatar }) });
}

/** Remove the learner and everything that points at them. */
async function deleteAccount(database, userId) {
  await Promise.all([
    database.collection('progress').deleteMany({ userId }),
    database.collection('friends').deleteMany({ $or: [{ userId }, { friendId: userId }] }),
    database.collection('feed').deleteMany({ actorId: userId }),
    database.collection('feed').updateMany({ likes: userId }, { $pull: { likes: userId } }),
    database.collection('chat').deleteMany({ userId }),
    database.collection('password_resets').deleteMany({ userId }),
  ]);
  await database.collection('users').deleteOne({ _id: userId });
}
