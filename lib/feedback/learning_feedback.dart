import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'haptics_native.dart' if (dart.library.js_interop) 'haptics_web.dart'
    as haptics;

enum FeedbackCue {
  tap,
  correct,
  retry,
  streak,
  hotStreak,
  complete,
  perfect,
  xpTick,
  combo,
  levelUp,
  goal,

  /// A press on a big button: a vibration only, never a sound.
  touch
}

abstract class FeedbackDriver {
  Future<void> play(FeedbackCue cue);
  Future<void> pulse(FeedbackCue cue);
  Future<void> stopSounds();
  void cancelHaptics();
}

class PlatformFeedbackDriver implements FeedbackDriver {
  /// One preloaded player per sound, so a cue starts instantly.
  final Map<FeedbackCue, AudioPlayer> _players = {};
  AudioPlayer? _current;
  int _generation = 0, _tickGeneration = 0;
  static const files = [
    'tap',
    'correct',
    'retry',
    'streak',
    'hot_streak',
    'complete',
    'perfect',
    'xp_tick',
    'combo',
    'level_up',
    'goal',
    '',
  ];

  /// Playback volume per cue. The files are mastered near the tutor voices'
  /// loudness; taps and ticks repeat a lot, so they sit a little lower.
  static double volume(FeedbackCue cue) => switch (cue) {
        FeedbackCue.tap => .55,
        FeedbackCue.xpTick => .5,
        FeedbackCue.retry => .85,
        _ => .9,
      };

  /// Vibration patterns in milliseconds: on, off, on, ... Each one follows
  /// the rhythm of its sound. Android can't feel pulses much under 10 ms.
  static const patterns = <FeedbackCue, List<int>>{
    FeedbackCue.tap: [14],
    FeedbackCue.correct: [22, 70, 38],
    FeedbackCue.retry: [55, 80, 55],
    FeedbackCue.streak: [20, 45, 20, 45, 45],
    FeedbackCue.hotStreak: [18, 35, 18, 35, 18, 35, 90],
    FeedbackCue.complete: [30, 60, 30, 60, 140],
    FeedbackCue.perfect: [24, 45, 24, 45, 24, 45, 40, 70, 180],
    FeedbackCue.xpTick: [9],
    FeedbackCue.combo: [18, 40, 36],
    FeedbackCue.levelUp: [35, 55, 35, 55, 35, 55, 60, 80, 120, 90, 240],
    FeedbackCue.goal: [30, 60, 30, 90, 160],
    FeedbackCue.touch: [10],
  };

  Future<AudioPlayer> _playerFor(FeedbackCue cue) async {
    final existing = _players[cue];
    if (existing != null) return existing;
    final player = AudioPlayer();
    _players[cue] = player;
    await player.setReleaseMode(ReleaseMode.stop);
    await player
        .setSource(AssetSource('audio/effects/${files[cue.index]}.wav'));
    await player.setVolume(volume(cue));
    return player;
  }

  @override
  Future<void> play(FeedbackCue cue) async {
    if (cue == FeedbackCue.touch) return;
    // Counting ticks have their own player so they never cut off a fanfare.
    final tick = cue == FeedbackCue.xpTick;
    final generation = tick ? ++_tickGeneration : ++_generation;
    bool stale() => generation != (tick ? _tickGeneration : _generation);
    try {
      if (!tick && _current != null) await _current!.stop();
      final player = await _playerFor(cue);
      if (stale()) return;
      await player.stop();
      if (stale()) return;
      if (!tick) _current = player;
      await player.resume();
    } catch (_) {/* Browser audio policies must never block a lesson. */}
  }

  @override
  Future<void> pulse(FeedbackCue cue) => haptics.pulse(patterns[cue] ?? [12],
      strong: cue == FeedbackCue.hotStreak ||
          cue == FeedbackCue.perfect ||
          cue == FeedbackCue.levelUp ||
          cue == FeedbackCue.goal);
  @override
  Future<void> stopSounds() async {
    _generation++;
    _tickGeneration++;
    try {
      for (final player in _players.values) {
        await player.stop();
      }
    } catch (_) {}
  }

  @override
  void cancelHaptics() => haptics.cancelPulse();
}

class LearningFeedback extends ChangeNotifier {
  final FeedbackDriver driver;
  LearningFeedback({FeedbackDriver? driver})
      : driver = driver ?? PlatformFeedbackDriver();
  bool sounds = true, vibration = true, spokenWords = true;
  Future<void>? _loading;
  Future<void> load() => _loading ??= _load();
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    sounds = prefs.getBool('feedback.sounds') ?? true;
    vibration = prefs.getBool('feedback.vibration') ?? true;
    spokenWords = prefs.getBool('feedback.spokenWords') ?? true;
    notifyListeners();
  }

  Future<void> setSounds(bool value) async {
    sounds = value;
    if (!value) await driver.stopSounds();
    notifyListeners();
    await (await SharedPreferences.getInstance())
        .setBool('feedback.sounds', value);
  }

  Future<void> setVibration(bool value) async {
    vibration = value;
    if (!value) driver.cancelHaptics();
    notifyListeners();
    await (await SharedPreferences.getInstance())
        .setBool('feedback.vibration', value);
  }

  Future<void> setSpokenWords(bool value) async {
    spokenWords = value;
    notifyListeners();
    await (await SharedPreferences.getInstance())
        .setBool('feedback.spokenWords', value);
  }

  static FeedbackCue answerCue(bool correct, int run) {
    if (!correct) return FeedbackCue.retry;
    if (run >= 5 && run % 5 == 0) return FeedbackCue.hotStreak;
    if (run == 3) return FeedbackCue.streak;
    return FeedbackCue.correct;
  }

  void _emit(FeedbackCue cue, {bool sound = true}) {
    if (sound && sounds) unawaited(driver.play(cue));
    if (vibration) unawaited(driver.pulse(cue));
  }

  bool shouldSpeakSelection(String language) => spokenWords && language == 'sr';
  void tap({bool sound = true}) => _emit(FeedbackCue.tap, sound: sound);
  void answer(bool correct, int run) => _emit(answerCue(correct, run));
  void complete({required bool passed, required bool perfect}) => _emit(!passed
      ? FeedbackCue.retry
      : perfect
          ? FeedbackCue.perfect
          : FeedbackCue.complete);

  DateTime _lastTickPulse = DateTime(0);

  /// A soft tick while XP counts up, with a light buzz every so often so the
  /// counter feels like it's rolling in your hand.
  void xpTick() {
    if (sounds) unawaited(driver.play(FeedbackCue.xpTick));
    final now = DateTime.now();
    if (vibration && now.difference(_lastTickPulse).inMilliseconds >= 110) {
      _lastTickPulse = now;
      unawaited(driver.pulse(FeedbackCue.xpTick));
    }
  }

  /// A press on a big button: vibration only.
  void touch() {
    if (vibration) unawaited(driver.pulse(FeedbackCue.touch));
  }

  void combo() => _emit(FeedbackCue.combo);
  void levelUp() => _emit(FeedbackCue.levelUp);
  void goal() => _emit(FeedbackCue.goal);
  Future<void> stopSounds() => driver.stopSounds();
  void cancelHaptics() => driver.cancelHaptics();
}

final learningFeedback = LearningFeedback();
