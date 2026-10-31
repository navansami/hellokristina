/// Microphone recognition is provided by the browser build.
class SerbianSpeech {
  static bool get supported => false;

  static Future<bool> start({
    required void Function(String transcript) onResult,
    required void Function() onEnd,
    required void Function(String reason) onError,
  }) async {
    return false;
  }

  static void stop() {}
}
