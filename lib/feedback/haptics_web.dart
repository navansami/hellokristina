import 'dart:js_interop';

@JS()
extension type _VibrationNavigator(JSObject _) implements JSObject {
  external JSFunction? get vibrate;
}
@JS('navigator')
external _VibrationNavigator get _navigator;
Future<void> pulse(List<int> pattern, {bool strong = false}) async {
  try {
    _navigator.vibrate?.callAsFunction(
        _navigator, pattern.map((value) => value.toJS).toList().toJS);
  } catch (_) {}
}

void cancelPulse() {
  pulse([0]);
}
