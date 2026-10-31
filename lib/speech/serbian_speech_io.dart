/// Microphone recognition is provided by the browser build.
class SerbianSpeech {
  /// Widget tests set this to show the microphone without a browser.
  static bool debugSupported = false;

  /// When set, [start] reports this transcript and then ends.
  static String? debugTranscript;

  static bool get supported => debugSupported;

  static Future<bool> start({
    required void Function(String transcript) onResult,
    required void Function() onEnd,
    required void Function(String reason) onError,
  }) async {
    final heard = debugTranscript;
    if (heard == null) return false;
    onResult(heard);
    onEnd();
    return true;
  }

  static void stop() {}
}
