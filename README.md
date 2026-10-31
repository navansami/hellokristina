# Hello Kristina

A mobile-first Flutter app for English speakers learning Serbian. The web build is designed for Vercel; the same Flutter code can target Android and iOS. A Vercel Node API connects to MongoDB Atlas and provides authentication, course progress, social features, admin course editing, AI lesson drafts, and Cloudinary upload signing.

## Run locally

1. Install Flutter and Node.js 20+.
2. Run `flutter pub get` and `flutter run -d chrome` for the learning UI. The starter lessons work offline and save progress locally.
3. Copy `.env.example` to `.env.local`, set MongoDB Atlas and `JWT_SECRET`, then run `npm install` and `npx vercel dev` for account and admin APIs. For a separate Flutter server, use `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000`.
4. Android and iOS project files are included. For native builds (iOS tooling requires macOS), set `--dart-define=API_BASE_URL=https://your-domain.vercel.app`.

## Deploy

Import this repository into Vercel. Set the environment variables in `.env.example`; `MONGODB_URI`, `MONGODB_DB`, and `JWT_SECRET` are required for accounts. The build script installs Flutter if needed and builds `build/web`. Vercel serves `/api` through Node functions and the Flutter build as static files. Set `ADMIN_EMAILS` before registering the admin account.

## Current scope

The playable starter path includes greetings, introductions, politeness, numbers, a café, and family. It has word review, the full 30-letter Serbian Cyrillic reference, local XP/progress, a default avatar with customization, and an animated Kristina portrait. Accounts, seven-day remember-me tokens, MongoDB progress, friends and likes, admin course CRUD, AI draft generation, and Cloudinary upload signing are implemented in the API. AI generation requires `OPENAI_API_KEY`; media signing requires Cloudinary keys. Generated lessons are drafts and should be reviewed before publication.

The A1–C2 curriculum and a trained personalization model are still product work: the current path is an initial playable slice, not a complete advanced course. A Bayesian knowledge tracing estimate now suggests review after missed answers; it is not a trained personalization model. Voice chat and production avatar art/animation are future integrations. Do not put service secrets in Flutter `--dart-define`; keep them in Vercel environment variables.

The optional AI chat endpoint is `/api/course/chat`; it uses the OpenAI Responses API and keeps recent turns in MongoDB. Its key stays on the server. The learner UI does not yet expose voice conversation.

`curriculum/serbian-en.json` is the planned A1–C2 progression. It is an outline, not published lesson content. The admin API can store reviewed courses with additional units and challenges as they are authored.
