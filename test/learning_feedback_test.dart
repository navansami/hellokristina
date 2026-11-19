import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hello_kristina/feedback/learning_feedback.dart';

class FakeDriver implements FeedbackDriver {
  final sounds = <FeedbackCue>[], pulses = <FeedbackCue>[];
  int stops = 0, cancels = 0;
  @override
  Future<void> play(FeedbackCue cue) async {
    sounds.add(cue);
  }

  @override
  Future<void> pulse(FeedbackCue cue) async {
    pulses.add(cue);
  }

  @override
  Future<void> stopSounds() async {
    stops++;
  }

  @override
  void cancelHaptics() {
    cancels++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('milestones celebrate 3, 5, 10 and a perfect finish', () async {
    final driver = FakeDriver();
    final controller = LearningFeedback(driver: driver);
    await controller.load();
    expect(driver.sounds, isEmpty);
    expect(controller.sounds, true);
    for (var run = 1; run <= 10; run++) controller.answer(true, run);
    expect(driver.sounds, [
      FeedbackCue.correct,
      FeedbackCue.correct,
      FeedbackCue.streak,
      FeedbackCue.correct,
      FeedbackCue.hotStreak,
      FeedbackCue.correct,
      FeedbackCue.correct,
      FeedbackCue.correct,
      FeedbackCue.correct,
      FeedbackCue.hotStreak
    ]);
    controller.complete(passed: true, perfect: true);
    expect(driver.sounds.last, FeedbackCue.perfect);
    controller.complete(passed: false, perfect: false);
    expect(driver.sounds.last, FeedbackCue.retry);
    expect(driver.pulses, driver.sounds);
  });
  test('sound and vibration switches work independently and persist', () async {
    final driver = FakeDriver(),
        controller = LearningFeedback(driver: FakeDriver());
    final feedback = LearningFeedback(driver: driver);
    await feedback.load();
    await feedback.setSounds(false);
    feedback.answer(true, 5);
    expect(driver.sounds, isEmpty);
    expect(driver.pulses, [FeedbackCue.hotStreak]);
    expect(driver.stops, 1);
    await feedback.setVibration(false);
    feedback.answer(true, 3);
    expect(driver.pulses.length, 1);
    expect(driver.cancels, 1);
    await feedback.setSounds(true);
    feedback.answer(true, 1);
    expect(driver.sounds, [FeedbackCue.correct]);
    await feedback.setSpokenWords(false);
    await controller.load();
    expect(controller.sounds, true);
    expect(controller.vibration, false);
    expect(controller.spokenWords, false);
  });
  test('only Serbian selections speak and they can omit tap sounds', () async {
    final driver = FakeDriver();
    final feedback = LearningFeedback(driver: driver);
    await feedback.load();
    expect(feedback.shouldSpeakSelection('sr'), true);
    expect(feedback.shouldSpeakSelection('en'), false);
    feedback.tap(sound: false);
    expect(driver.sounds, isEmpty);
    expect(driver.pulses, [FeedbackCue.tap]);
    await feedback.setSpokenWords(false);
    expect(feedback.shouldSpeakSelection('sr'), false);
    expect(feedback.sounds, true);
  });
  test('presses buzz silently, goals cheer and XP ticks buzz sparingly',
      () async {
    final driver = FakeDriver();
    final feedback = LearningFeedback(driver: driver);
    await feedback.load();
    feedback.touch();
    expect(driver.sounds, isEmpty);
    expect(driver.pulses, [FeedbackCue.touch]);
    feedback.goal();
    expect(driver.sounds, [FeedbackCue.goal]);
    driver.pulses.clear();
    for (var i = 0; i < 5; i++) {
      feedback.xpTick();
    }
    expect(driver.sounds.where((cue) => cue == FeedbackCue.xpTick).length, 5);
    expect(driver.pulses, [FeedbackCue.xpTick]);
    await feedback.setVibration(false);
    feedback.touch();
    expect(driver.pulses, [FeedbackCue.xpTick]);
  });

  test('every cue has a vibration and every sound has a file', () {
    for (final cue in FeedbackCue.values) {
      expect(PlatformFeedbackDriver.patterns[cue], isNotEmpty, reason: '$cue');
      if (cue != FeedbackCue.touch) {
        expect(PlatformFeedbackDriver.files[cue.index], isNotEmpty,
            reason: '$cue');
      }
    }
    expect(PlatformFeedbackDriver.files.length, FeedbackCue.values.length);
  });
}
