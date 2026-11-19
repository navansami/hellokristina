// Avatar pieces and how many options each has. lib/avatar/learner_look.dart
// defines the same ranges (LearnerLook.ranges); test/avatar_editor_test.dart
// checks the two agree.
export const AVATAR_RANGES = {
  skin: 20,
  face: 4,
  cheeks: 7,
  eyes: 9,
  eyeColor: 8,
  brows: 6,
  mouth: 8,
  hair: 20,
  hairColor: 16,
  facialHair: 5,
  glasses: 8,
  glassesColor: 10,
  earrings: 3,
  hat: 16,
  hatColor: 12,
  outfit: 12,
  outfitColor: 16,
  pattern: 6,
  background: 20,
  backdrop: 8,
  lips: 8,
  eyeshadow: 7,
  lashes: 3,
  accessory: 8,
  accessoryColor: 10,
};

export const DEFAULT_LOOK = { skin: 6, face: 0, cheeks: 1, eyes: 0, eyeColor: 0, brows: 1, mouth: 0, hair: 2, hairColor: 1, facialHair: 0, glasses: 0, glassesColor: 1, earrings: 0, hat: 0, hatColor: 1, outfit: 0, outfitColor: 4, pattern: 0, background: 0, backdrop: 1, lips: 0, eyeshadow: 0, lashes: 0, accessory: 0, accessoryColor: 0 };

/** A complete, in-range look, or null. */
export function readLook(raw) {
  if (!raw || typeof raw !== 'object') return null;
  const look = {};
  for (const [key, max] of Object.entries(AVATAR_RANGES)) {
    const value = raw[key];
    if (!Number.isInteger(value) || value < 0 || value >= max) return null;
    look[key] = value;
  }
  return look;
}
