import 'dart:js_interop';

extension type _Event(JSObject _) implements JSObject {
  external void preventDefault();
  external set returnValue(JSAny value);
}
extension type _Window(JSObject _) implements JSObject {
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
}
@JS('window')
external _Window get _window;

JSFunction? _listener;

void setLeaveGuard(bool on) {
  try {
    if (on && _listener == null) {
      final listener = ((_Event event) {
        // Browsers show their own "Leave site?" prompt for this.
        event.preventDefault();
        event.returnValue = ''.toJS;
      }).toJS;
      _listener = listener;
      _window.addEventListener('beforeunload', listener);
    } else if (!on && _listener != null) {
      _window.removeEventListener('beforeunload', _listener!);
      _listener = null;
    }
  } catch (_) {}
}
