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

The learner path reads `/api/course/catalog?courseId=serbian-en` from MongoDB. The same published seed is bundled in Flutter for offline use. `curriculum/serbian-en.v1.json` is the versioned source, and `assets/course/serbian-en.v1.json` must match it. Run `node scripts/validate-course.mjs` after editing either copy. The expanded A1 path has 11 units, 68 lessons, 424 challenges, short theory cards, and vocabulary in Latin and Cyrillic. Listening exercises offer normal and slow playback. Eleven checkpoints require 75%; the final 12-question knowledge check requires 80%. Failed checkpoints can be retried and do not unlock the next section. The previous six lesson IDs are preserved so existing progress carries forward.

Admins can open **Course studio**, load the published JSON, edit it, save a validated draft, and publish only after confirming a human review. `POST /api/admin/courses` saves a draft; `PATCH /api/admin/courses` with `{ "id": "serbian-en", "reviewed": true }` publishes it and archives the prior version. The public catalog serves only published content. AI lesson generation remains a separate draft tool; generated content must be checked and inserted into a course draft before publication.

`curriculum/serbian-en.json` remains the A1–C2 outline. The A1 path now covers personal details, food, travel, daily life, health, social situations, plans, and both scripts. It contains about 274 distinct vocabulary entries and is an expanded practice course. Spoken interaction, broader vocabulary coverage, and an independent Serbian language review are still needed before treating it as complete A1 preparation. Higher levels remain an outline.

## Serbian audio

The current A1 course includes 351 reusable MP3 pronunciations for its words and sentences. Learners can tap a speaker in the lesson theory cards, Serbian challenge prompts, answer feedback, and word bank. Audio is generated with OpenAI and labeled as AI-generated in the learner UI. The files are bundled with Flutter, so playing them does not call the API or require a device voice. New published content without a bundled recording falls back to a Serbian device voice when one is installed.

Audio references live in both copies of the course JSON. Run `node scripts/validate-course.mjs` to check that every referenced clip exists. To generate new clips after adding course content, set `OPENAI_API_KEY` in your local `.env` and run `node --env-file=.env scripts/generate-course-audio.mjs`. The generator only creates missing files. Its current Speech API model is scheduled for retirement in January 2027, so update the generator before then; existing bundled MP3 files will keep working.

## Other implemented features

The app has the Kristina mascot, a challenge path, word bank, 30-letter Cyrillic reference, XP and streaks, default avatar and customization, accounts with seven-day remember-me tokens, MongoDB progress, friends and likes, text AI chat, and admin AI draft generation. Course review suggestions use a Bayesian knowledge-tracing estimate, not a trained ML model. Cloudinary upload signing is available to admins; media management and voice practice are not yet in the learner app. Keep service secrets in Vercel environment variables, never in Flutter `--dart-define`.

## Visual design and animation

The exercise layout follows the supplied mobile references: a compact progress bar, character beside the prompt, outlined answer tiles, raised sentence tiles and buttons, and contextual feedback footer. Kristina is drawn as an articulated Flutter vector character in `lib/widgets/animated_kristina.dart`, with blinking, eye movement, head and arm gestures, correct/wrong expressions, and a brief celebration. It honors the device's reduced-motion preference. `learning_object.dart` supplies consistent illustrations for image questions, and `tactile_button.dart` provides the shared pressed button treatment.

## Course trail and practice rounds

The learner header (profile avatar, Serbian course selector, streak and XP) and icon-only bottom tabs stay fixed while the complete trail scrolls through all sections. Each circle contains five practice sessions. Sessions revisit the same lesson goal with shuffled question and answer order. Completing a session fills one of five ring segments; the next circle unlocks after all five. Previous completed lessons remain fully complete. Round progress is stored locally and in MongoDB; repeats do not award the same session XP again. Vocabulary is available after the first successful session.

Kristina is joined by Miloš (short dark hair and amber shirt) and Zara (glasses and teal shirt). The animated cast rotates through exercises and accompanies the trail. Run `node scripts/check-practice-rounds.mjs` to check progression, failure/retry behavior and compatibility with older completions.

## Exercise viewport and hints

Exercises size the heading, character/prompt, answer area and feedback to the available viewport; the exercise page has no vertical scroll. Choice tiles, image tiles and sentence banks adapt to smaller screens, and typed answers keep CHECK above the keyboard. Lesson guides use horizontal pages; completion fits the same screen. Underlined prompt words open vocabulary-backed translation and usage hints. Unrecognized words stay plain, and listening transcripts remain hidden before checking.

Run `flutter test test/lesson_viewport_test.dart` for viewport, keyboard, hint, guide and completion coverage. The suite checks the longest current examples of every exercise format at 320×568, 360×640 and 390×700.

Answer feedback is a bottom overlay. Its expansion covers the lower exercise area while preserving the prompt and answer positions; it never resizes or pushes the exercise upward.
