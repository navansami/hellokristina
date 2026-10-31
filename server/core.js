import { MongoClient, ObjectId } from 'mongodb';
import { SignJWT, jwtVerify } from 'jose';
import bcrypt from 'bcryptjs';

let clientPromise;
let indexPromise;
export async function db() {
  if (!process.env.MONGODB_URI) throw new Error('MONGODB_URI is not configured');
  clientPromise ||= new MongoClient(process.env.MONGODB_URI).connect();
  const client = await clientPromise;
  const database = client.db(process.env.MONGODB_DB || 'hello_kristina');
  indexPromise ||= Promise.all([
    database.collection('users').createIndex({ email: 1 }, { unique: true }),
    database.collection('users').createIndex({ username: 1 }, { unique: true }),
    database.collection('progress').createIndex({ userId: 1, courseId: 1 }, { unique: true }),
    database.collection('friends').createIndex({ userId: 1, friendId: 1 }, { unique: true }),
    database.collection('feed').createIndex({ actorId: 1, createdAt: -1 }),
  ]).catch(error => { indexPromise = undefined; throw error; });
  await indexPromise;
  return database;
}
export function send(res, status, data) { return res.status(status).json(data); }
export function method(req, res, allowed) {
  if (allowed.includes(req.method)) return true;
  res.setHeader('Allow', allowed.join(', ')); send(res, 405, { error: 'Method not allowed' }); return false;
}
export function safe(handler) { return async (req, res) => {
  const origin = req.headers.origin;
  if (origin && (/^https?:\/\/localhost(:\d+)?$/.test(origin) || origin === process.env.PUBLIC_ORIGIN)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
    res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PATCH, OPTIONS');
  }
  if (req.method === 'OPTIONS') return res.status(204).end();
  try { await handler(req, res); } catch (e) { console.error(e); send(res, e?.code === 11000 ? 409 : 500, { error: e?.code === 11000 ? 'That account already exists' : 'Something went wrong' }); }
}; }
export function secret() {
  if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) throw new Error('JWT_SECRET must be at least 32 characters');
  return new TextEncoder().encode(process.env.JWT_SECRET);
}
export async function token(user, remember = true) {
  return new SignJWT({ email: user.email, role: user.role || 'learner' }).setProtectedHeader({ alg: 'HS256' }).setSubject(String(user._id)).setIssuedAt().setExpirationTime(remember ? '7d' : '1d').sign(secret());
}
export async function userFrom(req) {
  const raw = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  if (!raw) return null;
  try {
    const { payload } = await jwtVerify(raw, secret());
    const user = await (await db()).collection('users').findOne({ _id: new ObjectId(payload.sub) }, { projection: { passwordHash: 0 } });
    return user;
  } catch { return null; }
}
export async function requireUser(req, res) {
  const user = await userFrom(req);
  if (!user) send(res, 401, { error: 'Please sign in again' });
  return user;
}
export async function requireAdmin(req, res) {
  const user = await requireUser(req, res);
  if (!user) return null;
  if (user.role !== 'admin') { send(res, 403, { error: 'Admin access required' }); return null; }
  return user;
}
export function publicUser(user) {
  return { id: String(user._id), name: user.name, username: user.username, email: user.email, avatar: user.avatar, role: user.role || 'learner', xp: user.xp || 0, streak: user.streak || 0, createdAt: user.createdAt };
}
export { bcrypt, ObjectId };
