// Social rules: who sees what, and which moments become feed posts.
// scripts/check-social.mjs checks the pure helpers.
import { levelForXp } from './xp.js';

/** Streak lengths worth celebrating in the feed. */
export const STREAK_MILESTONES = [3, 7, 14, 30, 50, 100, 150, 200, 365, 500, 1000];

/**
 * Feed posts earned by a finished session. `before` and `after` are the
 * learner's XP and streak around it; `lessonId` is set when a lesson circle
 * was newly completed.
 */
export function feedEvents({ before, after, lessonId }) {
  const events = [];
  if (lessonId) events.push({ type: 'lesson', lessonId });
  const fromLevel = levelForXp(before.xp || 0), toLevel = levelForXp(after.xp || 0);
  if (toLevel > fromLevel) events.push({ type: 'levelUp', level: toLevel });
  if (after.streak !== before.streak && STREAK_MILESTONES.includes(after.streak)) {
    events.push({ type: 'streak', streak: after.streak });
  }
  return events;
}

/** Post the events for `user`, who earned `xp` this session. */
export async function postFeedEvents(database, user, events, xp = 0) {
  if (!events.length) return;
  const now = new Date();
  await database.collection('feed').insertMany(events.map((event, i) => ({
    ...event,
    actorId: user._id,
    actorName: user.name,
    actorUsername: user.username,
    actorAvatar: user.avatar,
    xp,
    likes: [],
    // Keep the order stable when several land at once.
    createdAt: new Date(now.getTime() + i),
  })));
}

/** Escape text for a case-insensitive prefix search. */
export function searchPattern(text) {
  const clean = String(text ?? '').trim().replace(/^@/, '').slice(0, 30);
  return clean.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/** The public card for a person, as friends lists and search show it. */
export function personCard(person, { youFollow = false, followsYou = false } = {}) {
  return {
    id: String(person._id),
    name: person.name,
    username: person.username,
    avatar: person.avatar,
    xp: person.xp || 0,
    streak: person.streak || 0,
    level: levelForXp(person.xp || 0),
    youFollow,
    followsYou,
  };
}
