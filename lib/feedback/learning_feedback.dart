import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'haptics_native.dart' if (dart.library.js_interop) 'haptics_web.dart'
    as haptics;

enum FeedbackCue { tap, correct, retry, streak, hotStreak, complete, perfect }

abstract class FeedbackDriver {
  Future<void> play(FeedbackCue cue);
  Future<void> pulse(FeedbackCue cue);
  Future<void> stopSounds();
  void cancelHaptics();
}

class PlatformFeedbackDriver implements FeedbackDriver {
  AudioPlayer? _player;
  int _generation = 0;
  static const files = [
    'tap',
    'correct',
    'retry',
    'streak',
    'hot_streak',
    'complete',
    'perfect'
  ];
  static const patterns = [
    [7],
    [12],
    [8],
    [12, 45, 18],
    [14, 35, 20, 45, 24],
    [12, 50, 20],
    [18, 50, 25, 70, 35]
  ];
  @override
  Future<void> play(FeedbackCue cue) async {
    final generation = ++_generation;
    try {
      final player = _player ??= AudioPlayer();
      await player.stop();
      if (generation != _generation) return;
      await player
          .setSource(AssetSource('audio/effects/${files[cue.index]}.wav'));
      if (generation != _generation) return;
      await player.setVolume(cue == FeedbackCue.tap ? 0.20 : 0.5);
      if (generation == _generation) await player.resume();
    } catch (_) {/* Browser audio policies must never block a lesson. */}
  }

  @override
  Future<void> pulse(FeedbackCue cue) => haptics.pulse(patterns[cue.index],
      strong: cue == FeedbackCue.hotStreak || cue == FeedbackCue.perfect);
  @override
  Future<void> stopSounds() async {
    _generation++;
    try {
      await _player?.stop();
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
  Future<void> stopSounds() => driver.stopSounds();
  void cancelHaptics() => driver.cancelHaptics();
}

final learningFeedback = LearningFeedback();
