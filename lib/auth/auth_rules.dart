/// Account rules, mirroring `server/auth.js` so the form can explain a
/// problem before anything is sent. `test/auth_rules_test.dart` and
/// `scripts/check-auth.mjs` run the same cases from `scripts/auth-cases.json`.
library;

const reservedUsernames = {
  'admin', 'administrator', 'kristina', 'hellokristina', 'support', 'help', //
  'root', 'system', 'moderator', 'mod', 'staff', 'team', 'official', 'milos',
  'zara',
};

String normalizeUsername(String raw) {
  final trimmed = raw.trim();
  return (trimmed.startsWith('@') ? trimmed.substring(1) : trimmed)
      .toLowerCase();
}

String? nameError(String raw) {
  final name = raw.trim();
  if (name.length < 2) return 'Enter your name';
  if (name.length > 60) return 'Keep your name under 60 characters';
  return null;
}

String? usernameError(String raw) {
  final username = normalizeUsername(raw);
  if (username.length < 3) return 'Usernames need at least 3 characters';
  if (username.length > 20) return 'Usernames can have up to 20 characters';
  if (!RegExp(r'^[a-z][a-z0-9._]*$').hasMatch(username)) {
    return 'Start with a letter and use only letters, numbers, dots and underscores';
  }
  if (RegExp(r'[._]{2}').hasMatch(username) ||
      RegExp(r'[._]$').hasMatch(username)) {
    return 'Dots and underscores can’t be doubled or come last';
  }
  if (reservedUsernames.contains(username)) return 'That username is taken';
  return null;
}

String? emailError(String raw) {
  final email = raw.trim();
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) ||
      email.length > 254) {
    return 'Enter a valid email address';
  }
  return null;
}

String? passwordError(String raw) {
  if (raw.length < 8) return 'Use at least 8 characters';
  if (raw.length > 128) return 'Use at most 128 characters';
  if (!RegExp(r'[A-Za-z]').hasMatch(raw) || !RegExp(r'[0-9]').hasMatch(raw)) {
    return 'Use at least one letter and one number';
  }
  return null;
}
