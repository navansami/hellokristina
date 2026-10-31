import crypto from 'node:crypto';
import { safe, method, send, requireAdmin } from '../../server/core.js';
export default safe(async (req, res) => {
  if (!method(req, res, ['POST'])) return;
  if (!await requireAdmin(req, res)) return;
  const { CLOUDINARY_CLOUD_NAME: cloudName, CLOUDINARY_API_KEY: apiKey, CLOUDINARY_API_SECRET: apiSecret } = process.env;
  if (!cloudName || !apiKey || !apiSecret) return send(res, 503, { error: 'Cloudinary is not configured' });
  const timestamp = Math.floor(Date.now() / 1000); const folder = 'hello-kristina/courses';
  const signature = crypto.createHash('sha1').update(`folder=${folder}&timestamp=${timestamp}${apiSecret}`).digest('hex');
  send(res, 200, { cloudName, apiKey, timestamp, folder, signature });
});
