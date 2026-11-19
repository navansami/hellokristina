part of '../main.dart';

/// Exercises the learner keeps missing, weakest first.
///
/// An item counts as a mistake once it has been missed and its estimated
/// mastery, the Beta mean (1 + correct) / (2 + correct + wrong), is below
/// 0.6. One miss with no correct answer scores 0.33; a miss followed by two
/// correct answers reaches 0.6 and drops off the list. Speaking and pairs
/// games are left out because they don't make good quick-fire review.
List<Question> mistakeQuestions(
    Iterable<Lesson> source, Map<String, List<int>> memory) {
  final scored = <(double, Question)>[];
  final seen = <String>{};
  for (final lesson in source) {
    for (final question in practicePool(lesson)) {
      if (question.type == 'Speak the phrase' ||
          question.type == 'Match the pairs' ||
          !seen.add(question.id)) {
        continue;
      }
      final counts = memory[question.id];
      if (counts == null || counts[1] == 0) continue;
      final mastery = (1 + counts[0]) / (2 + counts[0] + counts[1]);
      if (mastery < .6) scored.add((mastery, question.copy(review: false)));
    }
  }
  scored.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final item in scored) item.$2];
}

/// The smallest mistakes session worth starting.
const minMistakeSession = 3;

/// Mistake sessions pass at 60% and, like replays, earn half XP.
bool mistakesPassed(List<bool> answers) =>
    answers.where((right) => right).length * 100 >= 60 * answers.length;
