import { safe, method, send, requireUser, db } from '../../server/core.js';
import { personCard, searchPattern } from '../../server/social.js';

// Follows, Duolingo-style: following is one-way and needs no approval.
// Each row in `friends` is { userId: follower, friendId: followed }.
//
// GET                    -> { following, followers }
// GET ?q=text            -> { results }   people matching a name or @username
// POST { username }      -> follow
// DELETE { username }    -> unfollow
export default safe(async (req, res) => {
  if (!method(req, res, ['GET', 'POST', 'DELETE'])) return;
  const user = await requireUser(req, res); if (!user) return;
  const database = await db();
  const rows = database.collection('friends');
  const users = database.collection('users');
  const projection = { name: 1, username: 1, avatar: 1, xp: 1, streak: 1 };

  if (req.method === 'GET') {
    const [outgoing, incoming] = await Promise.all([
      rows.find({ userId: user._id }).toArray(),
      rows.find({ friendId: user._id }).toArray(),
    ]);
    const following = new Set(outgoing.map(r => String(r.friendId)));
    const followers = new Set(incoming.map(r => String(r.userId)));
    const card = person => personCard(person, { youFollow: following.has(String(person._id)), followsYou: followers.has(String(person._id)) });

    const q = searchPattern(req.query?.q);
    if (q) {
      if (q.length < 2) return send(res, 200, { results: [] });
      const pattern = new RegExp(`^${q}`, 'i');
      const found = await users.find({ _id: { $ne: user._id }, $or: [{ username: pattern }, { name: pattern }] }, { projection }).limit(12).toArray();
      return send(res, 200, { results: found.map(card) });
    }

    const ids = [...new Set([...outgoing.map(r => r.friendId), ...incoming.map(r => r.userId)].map(String))];
    const people = await users.find({ _id: { $in: [...outgoing.map(r => r.friendId), ...incoming.map(r => r.userId)] } }, { projection }).toArray();
    const byId = new Map(people.map(p => [String(p._id), p]));
    const list = set => ids.filter(id => set.has(id) && byId.has(id)).map(id => card(byId.get(id)));
    return send(res, 200, { following: list(following), followers: list(followers), friends: list(following) });
  }

  const username = String(req.body?.username || '').trim().replace(/^@/, '').toLowerCase();
  const person = await users.findOne({ username }, { projection });
  if (!person || String(person._id) === String(user._id)) return send(res, 404, { error: 'Learner not found' });

  if (req.method === 'DELETE') {
    await rows.deleteOne({ userId: user._id, friendId: person._id });
    return send(res, 200, { person: personCard(person, { youFollow: false }) });
  }
  await rows.updateOne({ userId: user._id, friendId: person._id }, { $setOnInsert: { status: 'accepted', createdAt: new Date() } }, { upsert: true });
  const followsYou = Boolean(await rows.findOne({ userId: person._id, friendId: user._id }, { projection: { _id: 1 } }));
  send(res, 200, { person: personCard(person, { youFollow: true, followsYou }), friend: personCard(person, { youFollow: true, followsYou }) });
});
