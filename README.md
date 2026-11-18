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

The learner path reads `/api/course/catalog?courseId=serbian-en` from MongoDB. The same published seed is bundled in Flutter for offline use. `curriculum/serbian-en.v1.json` is the versioned source, and `assets/course/serbian-en.v1.json` must match it. Run `node scripts/validate-course.mjs` after editing either copy. The expanded A1 path has 11 units, 68 lessons, 424 challenges, short theory cards, and vocabulary in Latin and Cyrillic. Listening exercises offer normal and slow playback. Eleven checkpoints require 75%; the final knowledge check requires 80%. Failed checkpoints can be retried and do not unlock the next section. The previous six lesson IDs are preserved so existing progress carries forward.

Admins can open **Course studio**, load the published JSON, edit it, save a validated draft, and publish only after confirming a human review. `POST /api/admin/courses` saves a draft; `PATCH /api/admin/courses` with `{ "id": "serbian-en", "reviewed": true }` publishes it and archives the prior version. The public catalog serves only published content. AI lesson generation remains a separate draft tool; generated content must be checked and inserted into a course draft before publication.

`curriculum/serbian-en.json` remains the A1–C2 outline. The A1 path now covers personal details, food, travel, daily life, health, social situations, plans, and both scripts. It contains about 274 distinct vocabulary entries and is an expanded practice course. Spoken interaction, broader vocabulary coverage, and an independent Serbian language review are still needed before treating it as complete A1 preparation. Higher levels remain an outline.

## Serbian audio

The current A1 course includes 414 reusable MP3 pronunciations for its words and sentences. Learners can tap a speaker in the lesson theory cards, Serbian challenge prompts, answer feedback, and word bank. Audio is generated with OpenAI and labeled as AI-generated in the learner UI. The files are bundled with Flutter, so playing them does not call the API or require a device voice. New published content without a bundled recording falls back to a Serbian device voice when one is installed.

Audio references live in both copies of the course JSON. Run `node scripts/validate-course.mjs` to check that every referenced clip exists. To generate new clips after adding course content, set `OPENAI_API_KEY` in your local `.env` and run `node --env-file=.env scripts/generate-course-audio.mjs`. The generator only creates missing files. Its current Speech API model is scheduled for retirement in January 2027, so update the generator before then; existing bundled MP3 files will keep working.

## Other implemented features

The app has the Kristina mascot, a challenge path, word bank, 30-letter Cyrillic reference, XP and streaks, default avatar and customization, accounts with seven-day remember-me tokens, MongoDB progress, friends and likes, text AI chat, and admin AI draft generation. Course review suggestions use a Bayesian knowledge-tracing estimate, not a trained ML model. Cloudinary upload signing is available to admins; the learner app supports browser-based phrase repetition and falls back to word tiles when speech recognition is unavailable. Keep service secrets in Vercel environment variables, never in Flutter `--dart-define`.

## Visual design and animation

Lessons use a white canvas, pale blue vocabulary illustrations, orange actions, and green or red answer feedback. Word cards pair Latin and Cyrillic with English and offer normal and slow playback. When the unit contains a recorded example using the word, the card also shows the sentence and its translation. Learners can swipe through the cards or skip straight to practice. Kristina, Miloš, and Zara rotate through practice prompts, animate during playback, and react to answers and streaks.

## Course overview and practice rounds

The course opens at the learner’s current lesson. Illustrated unit headers stay pinned while lesson cards scroll. A five-part ring on each card shows completed sessions. The mobile navigation uses icons with tooltips and accessible names. Each lesson contains five practice sessions, and finishing all five unlocks the next lesson. Previous completions carry over. Progress is stored locally and in MongoDB. Repeating a session awards no additional XP, and vocabulary becomes available after the first successful session.

Run `node scripts/check-practice-rounds.mjs` to check progression, retries, and compatibility with older completions.

## Exercise viewport and hints

Exercises size the heading, character/prompt, answer area and feedback to the available viewport; the exercise page has no vertical scroll. Numbered choices, image tiles and sentence banks adapt to smaller screens. Learners answer with selections, word tiles or speech. Lesson guides use horizontal pages; completion fits the same screen. Underlined prompt words open vocabulary-backed translation and usage hints. Unrecognized words stay plain, and listening transcripts remain hidden before checking.

Run `flutter test test/lesson_viewport_test.dart` for viewport, speech fallback, hint, guide and completion coverage. The suite checks the longest current examples of every exercise format at 320×568, 360×640 and 390×700.

Answer feedback is a bottom overlay. Its expansion covers the lower exercise area while preserving the prompt and answer positions; it never resizes or pushes the exercise upward.

## Translation word banks and sentence completion

Course version 4 replaces sentence-sized multiple-choice translations with individual word banks, including wrong-word distractors. Tap tiles to build an answer on the lines, tap a selected tile to return it, or hold and drag selected tiles to change their order. Repeated words have separate tile identities. Listening translation uses the same word-bank interaction.

Choice exercises complete a Serbian sentence with one blank and three Serbian word options. A short English meaning cue disambiguates the intended sentence for beginners. Source-sentence speakers and tappable word hints remain available; the missing word's audio is available after checking. Lesson, question and practice-round IDs remain compatible with existing progress. `scripts/update-exercise-formats.mjs` documents the one-time v3-to-v4 content migration.


## Spoken selections, sound and vibration

Serbian word tiles and sentence choices speak when selected; English answer tiles stay silent. All 184 selectable Serbian words have bundled audio, including 63 extra recordings indexed by `assets/audio/serbian/word-index.json`. Speaking characters animate while pronunciation plays. To add missing selection clips after course changes, run `node --env-file=.env scripts/generate-word-audio.mjs`.

Lessons have quiet original tap/correct/retry sounds, milestones at three and five correct answers (and every five thereafter), and a perfect-practice chime with stronger character celebration. Gentle vibration uses Flutter haptics on native apps and the browser vibration API where supported. No permission prompts are added. Settings in the lesson header and the profile page offer separate persisted switches for automatic word pronunciation, sound effects and vibration. These switches do not disable manual pronunciation speakers. Playback stops on leaving a lesson or backgrounding the app, and pronunciation takes priority over effects.

Run `flutter test` and `node scripts/validate-feedback-assets.mjs` for preference/milestone, layout, audio-coverage and sound-level checks. The seven effect WAVs can be reproduced without external services using `python3 scripts/generate-feedback-sounds.py`.

## Living tutors, levels and rewards

Kristina, Miloš and Zara are spring-driven rigs, not floating pictures. Elbows, shoulders, head, brows, eyelids and mouth all blend between moods with anticipation, overshoot and follow-through. They wave hello when they appear and perform small idle acts (stretching, glancing around, touching their hair, bouncing). They nod when you pick an answer, rest a hand on the chin while you decide, cup an ear while the microphone listens and lip-sync while audio plays. They fist-pump, cheer or dance for correct runs and wince, shrug and recover after a mistake. Tapping a tutor makes it giggle and say a Serbian word. Reduced-motion settings freeze the tutors in a still pose.

Every finished session earns XP: +10 for passing, +2 per correct answer, +5 for a perfect round and +5 for five in a row. Replays earn half. A session that is not passed still earns 1 XP per correct answer. `server/xp.js` and `lib/game/progression.dart` share these rules and the level curve (40, 100, 180, 280 … total XP). Run `node scripts/check-xp.mjs` and `flutter test test/progression_test.dart` to check both. During a lesson a flame chip counts the run, the progress bar warms from blue to green to orange and each correct answer floats "+2 XP". The results screen counts XP up, pops in bonus chips, fills the level bar and celebrates a level-up with a fanfare, strong vibration and a dance. The course header shows a level medal with a progress ring that explains how XP is earned.
