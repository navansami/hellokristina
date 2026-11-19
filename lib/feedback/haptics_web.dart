import 'dart:async';
import 'dart:js_interop';

@JS()
extension type _VibrationNavigator(JSObject _) implements JSObject {
  external JSFunction? get vibrate;
}
@JS('navigator')
external _VibrationNavigator get _navigator;

extension type _Element(JSObject _) implements JSObject {
  external set innerHTML(String value);
  external void setAttribute(String name, String value);
  external void click();
  external void appendChild(_Element child);
  external void removeChild(_Element child);
}
extension type _Document(JSObject _) implements JSObject {
  external _Element createElement(String tag);
  external _Element? get head;
}
@JS('document')
external _Document get _document;

int _generation = 0;

/// Android browsers vibrate the pattern (on, off, on, ... in ms). Safari on
/// iPhone has no vibration API, but since iOS 18 toggling a switch control
/// gives a system haptic, so each "on" step becomes one of those taps.
Future<void> pulse(List<int> pattern, {bool strong = false}) async {
  final generation = ++_generation;
  try {
    final vibrate = _navigator.vibrate;
    if (vibrate != null) {
      vibrate.callAsFunction(
          _navigator, pattern.map((value) => value.toJS).toList().toJS);
      return;
    }
    var at = 0;
    for (var i = 0; i < pattern.length; i += 2) {
      if (at == 0) {
        _switchTap();
      } else {
        Timer(Duration(milliseconds: at), () {
          if (generation == _generation) _switchTap();
        });
      }
      at += pattern[i] + (i + 1 < pattern.length ? pattern[i + 1] : 0);
    }
  } catch (_) {}
}

void _switchTap() {
  try {
    final head = _document.head;
    if (head == null) return;
    final label = _document.createElement('label');
    label.setAttribute('aria-hidden', 'true');
    label.setAttribute('style', 'display:none');
    label.innerHTML = '<input type="checkbox" switch>';
    head.appendChild(label);
    label.click();
    head.removeChild(label);
  } catch (_) {}
}

void cancelPulse() {
  _generation++;
  try {
    _navigator.vibrate?.callAsFunction(_navigator, [0.toJS].toJS);
  } catch (_) {}
}
