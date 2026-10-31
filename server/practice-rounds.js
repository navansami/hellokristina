export function practiceResult(prior, lessonId, roundIndex, passed) {
  const alreadyComplete = (prior?.completedLessons || []).includes(lessonId);
  const key = `${lessonId}:${roundIndex ?? 'legacy'}`;
  const rounds = new Set(prior?.completedRounds || []);
  const newRound = !alreadyComplete && !rounds.has(key);
  if (passed && roundIndex !== undefined) rounds.add(key);
  const circleComplete = passed && (roundIndex === undefined || Array.from({ length: 5 }, (_, i) => `${lessonId}:${i}`).every(id => rounds.has(id)));
  return { key, newRound, circleComplete, count: alreadyComplete ? 5 : Array.from({ length: 5 }, (_, i) => `${lessonId}:${i}`).filter(id => rounds.has(id)).length };
}
