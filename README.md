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

The learner path reads `/api/course/catalog?courseId=serbian-en` from MongoDB. The same published seed is bundled in Flutter for offline use. `curriculum/serbian-en.v1.json` is the versioned source, and `assets/course/serbian-en.v1.json` must match it. Course version 5 is authored in `curriculum/src/serbian-a1.mjs` and compiled by `node scripts/build-course.mjs`, which writes both JSON copies and `curriculum/REVIEW.md`. Edit the source, not the JSON, then run `node scripts/validate-course.mjs`. The A1 path has 11 units, 44 lessons, 11 checkpoints (75%) and a final knowledge check (80%), with about 670 hand-written challenges. Each lesson teaches 8–10 words and one grammar point, such as noun gender, adjective agreement, *biti*, *imati*, the accusative ‑u, the locative, *da li* questions, the future with *ću*, modals with *da*, the past tense or *boli me*. Each lesson has six exercise kinds: sentences to build in Serbian, sentences to understand by ear, grammar gaps, dialogue replies (**Choose the reply**) and short readings (**Read and answer**), on top of word drills generated from the vocabulary. The builder makes Cyrillic and pronunciation guides automatically. Lesson IDs from version 4 are kept wherever the topic survives, so most progress carries over.

**The Serbian in version 5 was drafted with AI help and needs a native speaker's review.** `curriculum/REVIEW.md` lists every Serbian word, sentence, gap, reply and reading with its English for that review.

Admins can open **Course studio**, load the published JSON, edit it, save a validated draft, and publish only after confirming a human review. `POST /api/admin/courses` saves a draft; `PATCH /api/admin/courses` with `{ "id": "serbian-en", "reviewed": true }` publishes it and archives the prior version. The public catalog serves only published content. AI lesson generation remains a separate draft tool; generated content must be checked and inserted into a course draft before publication.

`curriculum/serbian-en.json` remains the A1–C2 outline. The A1 path now covers personal details, food, travel, daily life, health, social situations, plans, and both scripts. It contains about 274 distinct vocabulary entries and is an expanded practice course. Spoken interaction, broader vocabulary coverage, and an independent Serbian language review are still needed before treating it as complete A1 preparation. Higher levels remain an outline.

## Serbian audio

Every word and sentence has a recording in each tutor's voice: Kristina (OpenAI `marin`), Miloš (`cedar`) and Zara (`coral`). The voice always matches the tutor on screen. Lesson clips live in `assets/audio/serbian/`, with `milos/` and `zara/` variants beside them, and fall back to Kristina's recording. Clips are trimmed, gently compressed and set to −16 LUFS with peaks below −1.5 dBFS, so they play clearly on phone speakers. Learners can tap a speaker in the lesson theory cards, Serbian challenge prompts, answer feedback, and word bank. Audio is generated with OpenAI and labeled as AI-generated in the learner UI. The files are bundled with Flutter, so playing them does not call the API or require a device voice. New published content without a bundled recording falls back to a Serbian device voice when one is installed.

Audio references live in both copies of the course JSON. Run `node scripts/validate-course.mjs` to check that every referenced clip exists. After changing the course, run `node scripts/generate-audio.mjs --dry-run` to see how many clips are missing and what they will cost. Then run `node --env-file=.env scripts/generate-audio.mjs` with `OPENAI_API_KEY` set. It needs ffmpeg, either from `FFMPEG` or from `pip install imageio-ffmpeg`. `curriculum/audio-manifest.json` records the voice and text of every clip, so reruns only generate what changed, and unused clips are removed. `--sample` writes six test clips to `tmp/voice-samples/`. The Speech model `gpt-4o-mini-tts` is scheduled to retire in January 2027; update `MODEL` in the generator before then. Existing bundled MP3 files will keep working.

## Other implemented features

The app has the Kristina mascot, a challenge path, word bank, 30-letter Cyrillic reference, XP and streaks, default avatar and customization, accounts with seven-day remember-me tokens, MongoDB progress, friends and likes, text AI chat, and admin AI draft generation. Course review suggestions use a Bayesian knowledge-tracing estimate, not a trained ML model. Cloudinary upload signing is available to admins; the learner app supports browser-based phrase repetition and falls back to word tiles when speech recognition is unavailable. Keep service secrets in Vercel environment variables, never in Flutter `--dart-define`.

## Visual design and animation

The look is playful and modern: a warm cream canvas, indigo ink and candy accents. Headings and buttons use **Fredoka** and body text uses **Nunito**, which covers Serbian Latin and Cyrillic. Both fonts are bundled in `assets/google_fonts/` under the SIL Open Font License, so they work offline. The palette and the per-unit colour themes live in `lib/widgets/course_palette.dart`.

**The trail** (`lib/path/trail.dart`) winds down the screen in an S-curve like a road through Serbia:

- Each lesson is a chunky 3D coin that sinks when tapped, linked to the next by a dashed road that fills with the unit's colour as you go.
- A tappable signpost beside each coin shows the lesson name and progress. Pines, round trees, flowers and red-roofed houses dot the verges.
- The current lesson breathes, sends out a glowing halo, wears a bouncing START / CONTINUE bubble and shows its five-session ring. Its tutor stands beside it and waves.
- Checkpoints are larger trophy tiles that turn gold when passed. Locked stops are greyed out with a padlock.
- Every unit has its own colour story: coral, violet, teal, blue and so on. Its glossy banner pins while you scroll and shows a white Belgrade skyline, a progress bar and **JUMP HERE**.
- Tapping a stop opens a colourful lesson sheet with the five sessions and a big START button.

**Lessons:**

- The tutor speaks from a speech bubble.
- The progress bar is fat and glossy and warms from blue to green to orange as your run grows.
- Answer cards and word tiles have a 3D ledge, and Check is bright green.
- Right and wrong feedback slides up in a rounded panel.

The bottom navigation is a floating pill bar where the active tab grows a coloured label. Reduced-motion settings stop the trail's pulsing and bouncing.

Word cards pair Latin and Cyrillic with English and offer normal and slow playback. Kristina, Miloš and Zara rotate through practice prompts, animate during playback and react to answers and streaks.

## Course overview and practice rounds

The course opens at the learner’s current lesson. Illustrated unit headers stay pinned while lesson cards scroll. A five-part ring on each card shows completed sessions. The mobile navigation uses icons with tooltips and accessible names. Each lesson contains five practice sessions, and finishing all five unlocks the next lesson. Previous completions carry over. Progress is stored locally and in MongoDB. Repeating a session awards no additional XP, and vocabulary becomes available after the first successful session.

Sessions adapt to the learner, so lessons don't drag:

- **Length:** 7 questions for a new lesson, 5 when it is well known, 6 when mostly known and 8 when the learner is struggling. Checkpoints deal 10 and the final check deals 12.
- **Ring:** a flawless session fills three of the five segments and 85% or better fills two, so a strong learner finishes a lesson in two sessions. Passing a checkpoint fills its whole ring.
- **Mix:** about two in five questions are hand-written sentences, dialogues and readings, with at most one reading per session. Word drills fill the rest. No word appears more than twice in one session, and items from the last session are held back.
- **Review:** one or two items from earlier lessons, tagged REVIEW, favouring words the learner got wrong.
- **Retries:** a missed question comes back once at the end, tagged MISTAKE, preferably as a different exercise on the same word.
- **Exercises:** generated practice includes *Tap the matching pairs* and *Listen and choose*.
- **Jump ahead:** units ahead of the learner show **JUMP HERE**, a 12-question test. Scoring 80% completes every lesson up to that unit.

Run `node scripts/check-practice-rounds.mjs` to check progression, retries, and compatibility with older completions.

## Exercise viewport and hints

Exercises size the heading, character/prompt, answer area and feedback to the available viewport; the exercise page has no vertical scroll. Numbered choices, image tiles and sentence banks adapt to smaller screens. Learners answer with selections, word tiles or speech. Lesson guides use horizontal pages: a grammar page first, then one card per word. Completion fits the same screen. Underlined prompt words open vocabulary-backed translation and usage hints. Unrecognized words stay plain, and listening transcripts remain hidden before checking.

Run `flutter test test/lesson_viewport_test.dart` for viewport, speech fallback, hint, guide and completion coverage. The suite checks the longest current examples of every exercise format at 320×568, 360×640 and 390×700.

Answer feedback is a bottom overlay. Its expansion covers the lower exercise area while preserving the prompt and answer positions; it never resizes or pushes the exercise upward.

## Translation word banks and sentence completion

Course version 4 replaces sentence-sized multiple-choice translations with individual word banks, including wrong-word distractors. Tap tiles to build an answer on the lines, tap a selected tile to return it, or hold and drag selected tiles to change their order. Repeated words have separate tile identities. Listening translation uses the same word-bank interaction.

Choice exercises complete a Serbian sentence with one blank and three Serbian word options. A short English meaning cue disambiguates the intended sentence for beginners. Source-sentence speakers and tappable word hints remain available; the missing word's audio is available after checking. Lesson, question and practice-round IDs remain compatible with existing progress. `scripts/update-exercise-formats.mjs` documents the one-time v3-to-v4 content migration.


## Spoken selections, sound and vibration

Serbian word tiles and sentence choices speak when selected; English answer tiles stay silent. Every selectable Serbian word and reply has bundled audio, indexed by `assets/audio/serbian/word-index.json`; `scripts/generate-audio.mjs` keeps it up to date. Speaking characters animate while pronunciation plays.

Feedback sounds are original and synthesised from scratch by `scripts/generate-feedback-sounds.py` (standard-library Python, no third-party samples). The script builds marimba, FM-bell, plucked-string, bubble-pop, soft-kick and whoosh instruments, layers them into chords, arpeggios and sparkles, adds a small room reverb and masters each sound to a -1 dBFS peak. That puts effects at roughly the tutor voices' loudness (about -12 LUFS against the voices' -16, played at 50–90% volume). There are eleven cues: tap, correct, a gentle retry, three in a row, five in a row, combo, XP tick, practice complete, perfect, daily goal and level up. Each cue has its own preloaded player so it starts instantly. Pronunciation still takes priority over effects.

Every cue also has a vibration pattern that follows the rhythm of its sound. Big buttons buzz as they're pressed, and the XP counter buzzes as it rolls. On native apps the pattern becomes Flutter haptic taps, firmer for longer pulses. In Android browsers it uses the vibration API. Safari on iPhone has no vibration API, so the app makes a best-effort system haptic by toggling a hidden switch control (iOS 18 and later). No permission prompts are added. Settings in the lesson header and the profile page offer separate persisted switches for automatic word pronunciation, sound effects and vibration. These switches do not disable manual pronunciation speakers. Playback stops on leaving a lesson or backgrounding the app.

Run `flutter test` and `node scripts/validate-feedback-assets.mjs` for preference/milestone, layout, audio-coverage and sound-level checks. Regenerate the effects with `python scripts/generate-feedback-sounds.py`.

## Living tutors, levels and rewards

Kristina, Miloš and Zara are spring-driven rigs, not floating pictures. Elbows, shoulders, head, brows, eyelids and mouth all blend between moods with anticipation, overshoot and follow-through. They wave hello when they appear and perform small idle acts (stretching, glancing around, touching their hair, bouncing). They nod when you pick an answer, rest a hand on the chin while you decide, cup an ear while the microphone listens and lip-sync while audio plays. They fist-pump, cheer or dance for correct runs and wince, shrug and recover after a mistake. Tapping a tutor makes it giggle and say a Serbian word. Reduced-motion settings freeze the tutors in a still pose.

Every finished session earns XP: +10 for passing, +2 per correct answer, +5 for a perfect round and +5 for five in a row. Replays earn half. A session that is not passed still earns 1 XP per correct answer. `server/xp.js` and `lib/game/progression.dart` share these rules and the level curve (40, 100, 180, 280 … total XP). Run `node scripts/check-xp.mjs` and `flutter test test/progression_test.dart` to check both. During a lesson a flame chip counts the run, the progress bar warms from blue to green to orange and each correct answer floats "+2 XP". The results screen counts XP up, pops in bonus chips, fills the level bar and celebrates a level-up with a fanfare, strong vibration and a dance. The course header shows a level medal with a progress ring that explains how XP is earned.

## Daily goals, streaks and fixing mistakes

The course header shows the streak, a daily goal ring and the level medal. The flame cools to grey with a red dot when today's practice is still to do. Tapping the flame or the goal ring opens a sheet with the streak, this week's practice days and the daily goal (Casual 10, Regular 20, Serious 30 or Intense 50 XP). The day's XP, the goal and the practice days are kept on the device in `lib/game/daily_goal.dart`. Reaching the goal pops a "Daily goal reached!" badge on the results screen, which also throws confetti on every pass.

The Words tab offers a "Fix your mistakes" session once three or more exercises qualify. An exercise qualifies when it has been missed and its mastery estimate, (1 + correct) / (2 + correct + wrong), is below 0.6, so two correct answers after a miss clear it (`lib/practice/mistakes.dart`). A session deals up to 10 of the weakest, passes at 60% and earns half XP, like a replay. It counts towards the streak but not towards lesson progress. Signed-in learners post `{ review: true, answers }` to `/api/course/progress`, which applies the same rules.

The Words, Letters, Friends and Profile tabs share the trail's look: gradient hero banners, chunky cards and unit colours. Words are grouped by unit. Friends ranks your crew by total XP, with you included. Profile shows stat tiles, the daily goal and nine achievement medals.

## Safety checks before losing work

Leaving a lesson, checkpoint or test once an answer has been picked or given asks first ("Wait, don't go!"). This covers the close button, the Android back button and the browser back button. Keep learning is the big green button, and leaving is a quieter red option. On the web, closing or reloading the tab mid-lesson triggers the browser's own "Leave site?" prompt (`lib/platform/leave_guard*.dart`). The avatar editor asks before discarding an unsaved look, and signing out asks for confirmation. On Android, back from any other tab returns to Learn instead of closing the app. The shared sheet is `lib/widgets/confirm_sheet.dart`, and `test/safety_test.dart` covers each case.

## Accounts: sign up, log in, remember me and password reset

The app has no guest mode. Until someone is signed in it shows the front door (`lib/pages/auth_page.dart`): a welcome screen, sign up, log in, forgot password and the reset-link landing.

- **Sign up** asks for name, username, email, password (with confirmation) and agreement to a plain-language terms and privacy summary. Usernames are 3–20 characters, start with a letter, use letters, numbers, dots and underscores, and are checked live for availability. Passwords need 8+ characters with a letter and a number. `server/auth.js` and `lib/auth/auth_rules.dart` share these rules, and `scripts/auth-cases.json` holds the cases both `node scripts/check-auth.mjs` and `flutter test test/auth_test.dart` run.
- **Log in** takes an email or a username.
- **Remember me** (on by default) keeps the session on the device for 30 days. Unticked, the token lives only in the browser tab's `sessionStorage` (or in memory on native apps) and expires on the server within a day.
- **Forgot password** emails a one-hour link (`/?reset=…`) through [Resend](https://resend.com). Only a SHA-256 hash of the link's token is stored, and a reset signs out every existing session. Set `RESEND_API_KEY`, `MAIL_FROM` (for example `Hello Kristina <hello@your-domain>`, from a domain verified in Resend) and `PUBLIC_ORIGIN` (for example `https://hellokristina.app`). Without them, the form explains that reset emails aren't set up yet.
- **Expired sessions** (for example after a password reset) return the learner to the front door with a short note.

All of this runs in the existing `api/auth/register.js` (also `GET ?username=` for the live check) and `api/auth/login.js` (also `action: 'forgot' | 'reset'`), because the Vercel Hobby plan allows 12 functions and the project uses all 12.

## Account settings

The gear on the Profile tab, and the "Account settings" card near the bottom, open `lib/pages/account_page.dart`:

- **Profile:** change your name and username. Usernames follow the sign-up rules and must be free.
- **Login and security:**
  - Change your email (needs your current password).
  - Change your password (needs the current one, and signs out every other device while this one stays signed in).
  - "Sign out others", which ends every other session.
  - The page shows whether this device remembers you.
- **Learning:** daily goal, and the sound, vibration and spoken-word switches.
- **Sign out** and **Delete account.** Deleting needs your password and an "I understand" tick. It removes the user, progress, friendships in both directions, feed posts and likes, chat history and reset links.

The server side is `api/auth/profile.js`: `PATCH` with `details`, `email`, `password`, `action: 'signOutEverywhere'` or `avatar`, and `DELETE` to delete. Ending sessions sets `sessionsValidAfter` on the user, and `server/core.js` rejects older tokens. `test/account_test.dart` covers each flow.

## Avatars

Avatars are chibi-style busts drawn piece by piece in `lib/avatar/learner_portrait.dart`, so every option mixes with every other. `LearnerLook` (`lib/avatar/learner_look.dart`) holds 25 pieces:

- **Face:** 20 skin tones (16 natural plus 4 just-for-fun), 4 face shapes, and 7 cheek styles (rosy, freckles, heart or star stickers, a plaster).
- **Eyes:** 9 eye styles (bright, sparkly, happy, sleepy, wink, starry, hearts, dots, lashes), 8 eye colours and 6 brow shapes.
- **Mouth:** 8 mouths.
- **Hair:** 20 hairstyles, 16 hair colours (natural and bright) and 5 facial-hair options.
- **Extras:** 8 glasses styles (including star and heart shades) in 10 colours, and studs or hoops.
- **Hats:** 16 headwear options, among them beanie, caps, beret, a Serbian šajkača, crown, flower crown, headphones, cat and bunny ears and a wizard hat, in 12 colours.
- **Outfit:** 12 outfits, among them hoodie, dungarees, turtleneck, pinafore dress, lace Peter Pan collar, ruffles and a Serbian folk vest (jelek), in 16 colours and 6 patterns.
- **Make-up:** 7 lip colours (bare by default) and 6 eyeshadows. Lashes (flirty or bold) work with any eye style.
- **Hair accessories:** star clips, heart clip, flower clip, tiara, pearl pins, butterfly clip and a scrunchie that sits where the hair is tied, in 10 colours.
- **Background:** 20 background colours with 8 backdrops (dots, stars, sunburst, hearts, waves, confetti, city).

The editor (`lib/avatar/avatar_editor.dart`) shows a living preview that breathes, blinks and pops with sparkles on every change. It has emoji category tabs, mini previews of each option, a 🎲 "Surprise me" button, undo, and asks before discarding changes. Reduced-motion settings keep the preview still.

Saved first-generation looks convert to the nearest new pieces, and their colours stay identical because the old palettes are kept as the first entries. `server/avatar.js` holds the allowed ranges and the default look for new accounts. `test/avatar_editor_test.dart` checks that the server and the app agree.

## Course drop-down

Tapping the flag in the course header slides a panel down over a dimmed trail (`lib/path/course_switcher.dart`). It holds:
- **Course tiles:** big 3D tiles for Serbian (the current course, ringed in blue), "Chat with Kristina", and a dashed "More soon" tile.
- **Level card:** your CEFR level (A1 → A2) on a glowing lime progress bar with a sparkle at its tip, plus lessons done, words learned and total XP. "About your level" explains the scale.
- **Keep practising:** colourful shortcuts to chat, fix your mistakes (with a count badge) and the daily goal.

Tapping outside the panel, or the flag again, closes it.

## Letters with pronunciation

The Letters tab speaks. Tapping any of the 30 letters plays its Serbian name (а, бе, ве…) in Kristina's voice, and the big letter tile replays it. Each letter also has an example word that starts with it (Б → банана 🍌, Ж → жаба 🐸, Ш → шешир 🎩), with its own play button, the Latin spelling and the English meaning.

`curriculum/alphabet.json` is the source: letter, Latin twin, sound hint, letter name and example word. `scripts/generate-audio.mjs` records the letter names (with a letter-specific voice instruction) and any example words not already in the course. It writes `assets/course/alphabet.json` with the audio paths, and the app loads that file at start-up. `test/letters_test.dart` checks that every example starts with its letter in both scripts, that every clip exists, and that the bundled file matches the source. The example words are AI-drafted and belong in the native-speaker review.
