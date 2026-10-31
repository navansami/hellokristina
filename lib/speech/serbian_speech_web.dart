import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS()
extension type _Global(JSObject _) implements JSObject {
  external JSFunction? get SpeechRecognition;
  external JSFunction? get webkitSpeechRecognition;
}

@JS('globalThis')
external _Global get _global;

@JS()
extension type _Recognition(JSObject _) implements JSObject {
  external set lang(JSString value);
  external set interimResults(JSBoolean value);
  external set continuous(JSBoolean value);
  external set onresult(JSFunction? value);
  external set onerror(JSFunction? value);
  external set onend(JSFunction? value);
  external void start();
  external void stop();
}

@JS()
extension type _SpeechEvent(JSObject _) implements JSObject {
  external _ResultList get results;
}

@JS()
extension type _ResultList(JSObject _) implements JSObject {
  external int get length;
  external _SpeechResult item(int index);
}

@JS()
extension type _SpeechResult(JSObject _) implements JSObject {
  external int get length;
  external _SpeechAlternative item(int index);
}

@JS()
extension type _SpeechAlternative(JSObject _) implements JSObject {
  external String get transcript;
}

@JS()
extension type _SpeechError(JSObject _) implements JSObject {
  external String get error;
}

class SerbianSpeech {
  static int _generation = 0;
  static _Recognition? _active;

  static JSFunction? get _constructor {
    try {
      return _global.SpeechRecognition ?? _global.webkitSpeechRecognition;
    } catch (_) {
      return null;
    }
  }

  static bool get supported => _constructor != null;

  static Future<bool> start({
    required void Function(String transcript) onResult,
    required void Function() onEnd,
    required void Function(String reason) onError,
  }) async {
    stop();
    final ctor = _constructor;
    if (ctor == null) return false;
    final generation = ++_generation;
    try {
      final recognition = ctor.callAsConstructor<_Recognition>();
      _active = recognition;
      recognition.lang = 'sr-RS'.toJS;
      recognition.interimResults = true.toJS;
      recognition.continuous = false.toJS;
      recognition.onresult = ((JSObject event) {
        if (generation != _generation) return;
        onResult(_transcript(event));
      }).toJS;
      recognition.onerror = ((JSObject event) {
        if (generation != _generation) return;
        final reason = _reason(event);
        if (reason == 'no-speech' || reason == 'aborted') {
          onEnd();
          return;
        }
        onError(reason);
      }).toJS;
      recognition.onend = ((JSObject _) {
        if (generation != _generation) return;
        onEnd();
      }).toJS;
      recognition.start();
      return true;
    } catch (_) {
      _active = null;
      return false;
    }
  }

  static void stop() {
    _generation++;
    final active = _active;
    _active = null;
    try {
      active?.stop();
    } catch (_) {}
  }
}

String _transcript(JSObject event) {
  try {
    final results = _SpeechEvent(event).results;
    final parts = <String>[];
    for (var i = 0; i < results.length; i++) {
      final result = results.item(i);
      if (result.length > 0) parts.add(result.item(0).transcript);
    }
    return parts.join(' ').trim();
  } catch (_) {
    return '';
  }
}

String _reason(JSObject event) {
  try {
    return _SpeechError(event).error;
  } catch (_) {
    return 'unavailable';
  }
}
