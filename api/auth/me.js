import { safe, method, send, requireUser, publicUser } from '../../server/core.js';
export default safe(async (req, res) => { if (!method(req, res, ['GET'])) return; const user = await requireUser(req, res); if (user) send(res, 200, { user: publicUser(user) }); });
