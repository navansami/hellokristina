// Account rules shared by the auth routes. lib/auth/auth_rules.dart mirrors
// the validation so the app can explain problems before a request is sent;
// scripts/check-auth.mjs checks both behave the same.
import { createHash, randomBytes } from 'node:crypto';

export const RESERVED_USERNAMES = new Set(['admin', 'administrator', 'kristina', 'hellokristina', 'support', 'help', 'root', 'system', 'moderator', 'mod', 'staff', 'team', 'official', 'milos', 'zara']);

/** Lowercase, trimmed, and with a leading @ removed. */
export function normalizeUsername(raw) {
  return String(raw ?? '').trim().replace(/^@/, '').toLowerCase();
}

export function nameError(raw) {
  const name = String(raw ?? '').trim();
  if (name.length < 2) return 'Enter your name';
  if (name.length > 60) return 'Keep your name under 60 characters';
  return null;
}

export function usernameError(raw) {
  const username = normalizeUsername(raw);
  if (username.length < 3) return 'Usernames need at least 3 characters';
  if (username.length > 20) return 'Usernames can have up to 20 characters';
  if (!/^[a-z][a-z0-9._]*$/.test(username)) return 'Start with a letter and use only letters, numbers, dots and underscores';
  if (/[._]{2}/.test(username) || /[._]$/.test(username)) return 'Dots and underscores can’t be doubled or come last';
  if (RESERVED_USERNAMES.has(username)) return 'That username is taken';
  return null;
}

export function emailError(raw) {
  const email = String(raw ?? '').trim();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) || email.length > 254) return 'Enter a valid email address';
  return null;
}

export function passwordError(raw) {
  const password = String(raw ?? '');
  if (password.length < 8) return 'Use at least 8 characters';
  if (password.length > 128) return 'Use at most 128 characters';
  if (!/[A-Za-z]/.test(password) || !/[0-9]/.test(password)) return 'Use at least one letter and one number';
  return null;
}

/** Remembered sessions last 30 days; others last a day at most. */
export function sessionLength(remember) {
  return remember ? '30d' : '1d';
}

/** Password reset links: a random token for the email, only its hash stored. */
export const RESET_MINUTES = 60;
export function newResetToken() {
  const token = randomBytes(32).toString('base64url');
  return { token, hash: hashResetToken(token) };
}
export function hashResetToken(token) {
  return createHash('sha256').update(String(token)).digest('hex');
}

/**
 * Send the reset email through Resend (https://resend.com). Needs
 * RESEND_API_KEY and MAIL_FROM (e.g. "Hello Kristina <hello@hellokristina.app>").
 * Returns false when email isn't configured.
 */
export async function sendResetEmail({ to, name, link }) {
  const key = process.env.RESEND_API_KEY, from = process.env.MAIL_FROM;
  if (!key || !from) return false;
  const greeting = name ? `Zdravo ${escapeHtml(name)}!` : 'Zdravo!';
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      from,
      to: [to],
      subject: 'Reset your Hello Kristina password',
      text: `${name ? `Zdravo ${name}!` : 'Zdravo!'}\n\nSomeone asked to reset the password for your Hello Kristina account. Open this link within ${RESET_MINUTES} minutes to choose a new one:\n\n${link}\n\nIf it wasn't you, ignore this email and your password stays the same.`,
      html: `<div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;color:#221C3F"><h2 style="color:#F2622E">${greeting}</h2><p>Someone asked to reset the password for your Hello Kristina account. Use the button within ${RESET_MINUTES} minutes to choose a new one.</p><p><a href="${escapeHtml(link)}" style="display:inline-block;background:#F2622E;color:#fff;padding:12px 22px;border-radius:12px;text-decoration:none;font-weight:bold">Choose a new password</a></p><p style="color:#6D6890;font-size:13px">If it wasn’t you, ignore this email and your password stays the same.</p></div>`,
    }),
  });
  if (!response.ok) throw new Error(`Email failed: ${response.status}`);
  return true;
}

function escapeHtml(text) {
  return String(text).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

/** Where reset links point: the configured site, else the request's host. */
export function siteOrigin(req) {
  if (process.env.PUBLIC_ORIGIN) return process.env.PUBLIC_ORIGIN.replace(/\/$/, '');
  const host = req.headers['x-forwarded-host'] || req.headers.host || 'hellokristina.app';
  return `https://${host}`;
}
