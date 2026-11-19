import 'dart:js_interop';

extension type _Storage(JSObject _) implements JSObject {
  external JSString? getItem(String key);
  external void setItem(String key, String value);
  external void removeItem(String key);
}
extension type _History(JSObject _) implements JSObject {
  external void replaceState(JSAny? data, String title, String url);
}
extension type _Location(JSObject _) implements JSObject {
  external String get search;
  external String get pathname;
  external String get hash;
}
@JS('sessionStorage')
external _Storage get _session;
@JS('history')
external _History get _history;
@JS('location')
external _Location get _location;

const _key = 'hk.sessionToken';

String? readSessionToken() {
  try {
    return _session.getItem(_key)?.toDart;
  } catch (_) {
    return null;
  }
}

void writeSessionToken(String? token) {
  try {
    if (token == null) {
      _session.removeItem(_key);
    } else {
      _session.setItem(_key, token);
    }
  } catch (_) {}
}

/// The `?reset=` token from a password-reset email link, if any.
String? initialResetToken() {
  try {
    final token =
        Uri.splitQueryString(_location.search.replaceFirst('?', ''))['reset'];
    return token == null || token.isEmpty ? null : token;
  } catch (_) {
    return null;
  }
}

/// Drop `?reset=` from the address bar so a reload doesn't reuse it.
void clearResetFromUrl() {
  try {
    _history.replaceState(null, '', '${_location.pathname}${_location.hash}');
  } catch (_) {}
}
