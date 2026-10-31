# Hello Kristina

A mobile-first Flutter app for English speakers learning Serbian. The web build is designed for Vercel; the same Flutter code can target Android and iOS. A Vercel Node API connects to MongoDB Atlas and provides authentication, course progress, social features, admin course editing, AI lesson drafts, and Cloudinary upload signing.

## Run locally

1. Install Flutter and Node.js 20+.
2. Run `flutter pub get` and `flutter run -d chrome` for the learning UI. The starter lessons work offline and save progress locally.
3. Copy `.env.example` to `.env.local`, set MongoDB Atlas and `JWT_SECRET`, then run `npm install` and `npx vercel dev` for account and admin APIs. For a separate Flutter server, use `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000`.
4. Android and iOS project files are included. For native builds (iOS tooling requires macOS), set `--dart-define=API_BASE_URL=https://your-domain.vercel.app`.

## Deploy

Import this repository into Vercel. Set the environment variables in `.env.example`; `MONGODB_URI`, `MONGODB_DB`, and `JWT_SECRET` are required for accounts. The build script installs Flutter if needed and builds `build/web`. Vercel serves `/api` through Node functions and the Flutter build as static files. Set `ADMIN_EMAILS` before registering the admin account.

## Course content and publishing

The learner path reads `/api/course/catalog?courseId=serbian-en` from MongoDB. The same published seed is bundled in Flutter for offline use. `curriculum/serbian-en.v1.json` is the versioned source, and `assets/course/serbian-en.v1.json` must match it. Run `node scripts/validate-course.mjs` after editing either copy. The current A1 foundation has two units, 12 lessons, 48 challenges, short theory cards, and vocabulary in Latin and Cyrillic. The previous six lesson IDs are preserved so existing progress carries forward.

Admins can open **Course studio**, load the published JSON, edit it, save a validated draft, and publish only after confirming a human review. `POST /api/admin/courses` saves a draft; `PATCH /api/admin/courses` with `{ "id": "serbian-en", "reviewed": true }` publishes it and archives the prior version. The public catalog serves only published content. AI lesson generation remains a separate draft tool; generated content must be checked and inserted into a course draft before publication.

`curriculum/serbian-en.json` remains the A1–C2 outline. Two starter A1 units are playable, but the full A1–C2 course is not yet authored. The next content work is completing A1 with more grammar, listening, speaking, review, and assessment, then building higher levels.

## Other implemented features

The app has the Kristina mascot, a challenge path, word bank, 30-letter Cyrillic reference, XP and streaks, default avatar and customization, accounts with seven-day remember-me tokens, MongoDB progress, friends and likes, text AI chat, and admin AI draft generation. Course review suggestions use a Bayesian knowledge-tracing estimate, not a trained ML model. Cloudinary upload signing is available to admins; media management and voice practice are not yet in the learner app. Keep service secrets in Vercel environment variables, never in Flutter `--dart-define`.
