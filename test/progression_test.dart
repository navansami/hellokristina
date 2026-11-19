import 'package:flutter_test/flutter_test.dart';
import 'package:hello_kristina/game/progression.dart';

void main() {
  List<bool> all(int n) => List.filled(n, true);
  test('session XP matches server/xp.js', () {
    int xp(List<bool> a, bool passed, bool first) =>
        sessionReward(a, passed: passed, firstTime: first).total;
    expect(bestRun([true, true, false, true, true, true]), 3);
    expect(xp(all(8), true, true), 36);
    expect(xp(all(12), true, true), 44);
    expect(xp(all(8), true, false), 18);
    const six = [true, true, true, false, true, true, true, false];
    expect(xp(six, true, true), 22);
    expect(xp(six, true, false), 11);
    expect(
        xp([true, false, false, true, false, false, false, false], false, true),
        2);
  });
  test('levels grow by 20 XP each', () {
    expect([1, 2, 3, 4, 5, 10].map(xpForLevel), [0, 40, 100, 180, 280, 1080]);
    expect([0, 39, 40, 99, 100, 1080].map(levelForXp), [1, 1, 2, 2, 3, 10]);
    expect(levelProgress(70), closeTo(.5, 1e-9));
  });
  test('daily streak continues, holds and resets', () {
    final today = DateTime(2026, 11, 19, 9);
    expect(nextStreak(0, null, today), 1);
    expect(nextStreak(4, DateTime(2026, 11, 19, 1), today), 4);
    expect(nextStreak(4, DateTime(2026, 11, 18, 23), today), 5);
    expect(nextStreak(4, DateTime(2026, 11, 16), today), 1);
  });
  test('strong sessions fill more of the ring', () {
    expect(segmentsEarned(all(6), passed: true), 3);
    expect(segmentsEarned([...all(6), false], passed: true), 2);
    expect(segmentsEarned([...all(4), false, false], passed: true), 1);
    expect(segmentsEarned(all(6), passed: false), 0);
    expect(segmentsEarned(all(8), passed: true, kind: 'checkpoint'), 5);
    expect(claimRounds({}, 'hi', 0, 3), ['hi:0', 'hi:1', 'hi:2']);
    expect(claimRounds({'hi:0', 'hi:1', 'hi:2'}, 'hi', 3, 3), ['hi:3', 'hi:4']);
    expect(claimRounds({'hi:0'}, 'hi', 0, 1), ['hi:1']);
  });
}
