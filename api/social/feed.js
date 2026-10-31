import { safe, method, send, requireUser, db, ObjectId } from '../../server/core.js';
export default safe(async (req, res) => {
  if (!method(req, res, ['GET', 'POST'])) return;
  const user = await requireUser(req, res); if (!user) return;
  const database = await db();
  if (req.method === 'GET') {
    const friends = await database.collection('friends').find({ userId: user._id, status: 'accepted' }).toArray();
    const ids = [user._id, ...friends.map(f => f.friendId)];
    const items = await database.collection('feed').find({ actorId: { $in: ids } }).sort({ createdAt: -1 }).limit(30).toArray();
    return send(res, 200, { items: items.map(x => ({ ...x, id: String(x._id), _id: undefined, actorId: undefined, liked: x.likes?.some(id => String(id) === String(user._id)), likeCount: x.likes?.length || 0, likes: undefined })) });
  }
  const { itemId } = req.body || {}; if (!ObjectId.isValid(itemId)) return send(res, 400, { error: 'Invalid item' });
  const item = await database.collection('feed').findOne({ _id: new ObjectId(itemId) }); if (!item) return send(res, 404, { error: 'Post not found' });
  const liked = item.likes?.some(id => String(id) === String(user._id));
  await database.collection('feed').updateOne({ _id: item._id }, liked ? { $pull: { likes: user._id } } : { $addToSet: { likes: user._id } });
  send(res, 200, { liked: !liked, likeCount: (item.likes?.length || 0) + (liked ? -1 : 1) });
});
