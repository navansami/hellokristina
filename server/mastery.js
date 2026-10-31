// Bayesian knowledge tracing: prior mastery, learn transition, guess and slip.
export function updateMastery(prior, answers) {
  let p = Number.isFinite(prior) ? Math.min(.999, Math.max(.001, prior)) : .25;
  for (const correct of answers) {
    const observed = correct ? (p * .9) / (p * .9 + (1 - p) * .2) : (p * .1) / (p * .1 + (1 - p) * .8);
    p = observed + (1 - observed) * .12;
  }
  return Math.round(p * 1000) / 1000;
}
export function recommendation(progress, order) {
  const completed = new Set(progress?.completedLessons || []);
  const mastery = progress?.mastery || {};
  const review = order.filter(id => completed.has(id) && (mastery[id] ?? 1) < .8).sort((a,b) => (mastery[a] ?? 1) - (mastery[b] ?? 1))[0];
  if (review) return { lessonId: review, reason: 'review', mastery: mastery[review] };
  const next = order.find(id => !completed.has(id));
  return next ? { lessonId: next, reason: 'new', mastery: mastery[next] ?? .25 } : { lessonId: order[0], reason: 'refresh', mastery: mastery[order[0]] ?? 1 };
}
