import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { nameError, usernameError, emailError, passwordError, normalizeUsername, sessionLength, newResetToken, hashResetToken } from '../server/auth.js';

// The same cases run in test/auth_rules_test.dart, so app and server agree.
const cases = JSON.parse(readFileSync('scripts/auth-cases.json', 'utf8'));
const rules = { name: nameError, username: usernameError, email: emailError, password: passwordError };
let count = 0;
for (const [field, list] of Object.entries(cases)) {
  for (const [input, expected] of list) {
    assert.equal(rules[field](input), expected, `${field}: ${JSON.stringify(input)}`);
    count++;
  }
}
assert.equal(normalizeUsername(' @Ana.S '), 'ana.s');
assert.equal(sessionLength(true), '30d');
assert.equal(sessionLength(false), '1d');
const { token, hash } = newResetToken();
assert(token.length >= 40, 'reset tokens are long and random');
assert.equal(hash, hashResetToken(token));
assert.notEqual(hash, token, 'only the hash is stored');
assert.notEqual(newResetToken().token, token);
console.log(`${count} account rule cases, session lengths and reset tokens pass.`);
