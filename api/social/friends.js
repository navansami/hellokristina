import { safe, method, send, requireUser, db } from '../../server/core.js';
export default safe(async (req, res) => {
  if (!method(req, res, ['GET', 'POST'])) return;
  const user = await requireUser(req, res); if (!user) return; const database = await db();
  if (req.method === 'GET') {
    const rows = await database.collection('friends').find({ userId: user._id }).toArray();
    const friends = await Promise.all(rows.map(async row => { const person = await database.collection('users').findOne({ _id: row.friendId }, { projection: { name: 1, username: 1, avatar: 1, xp: 1, streak: 1 } }); return person && { id: String(person._id), ...person, _id: undefined, status: row.status }; }));
    return send(res, 200, { friends: friends.filter(Boolean) });
  }
  const username = String(req.body?.username || '').trim().toLowerCase();
  const friend = await database.collection('users').findOne({ username });
  if (!friend || String(friend._id) === String(user._id)) return send(res, 404, { error: 'Learner not found' });
  await database.collection('friends').updateOne({ userId: user._id, friendId: friend._id }, { $setOnInsert: { status: 'accepted', createdAt: new Date() } }, { upsert: true });
  await database.collection('friends').updateOne({ userId: friend._id, friendId: user._id }, { $setOnInsert: { status: 'accepted', createdAt: new Date() } }, { upsert: true });
  send(res, 200, { friend: { id: String(friend._id), name: friend.name, username: friend.username, avatar: friend.avatar, xp: friend.xp, streak: friend.streak } });
});
