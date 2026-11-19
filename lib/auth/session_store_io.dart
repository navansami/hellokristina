String? _token;

String? readSessionToken() => _token;
void writeSessionToken(String? token) => _token = token;

/// A password-reset token from the opening link (web only).
String? initialResetToken() => null;
void clearResetFromUrl() {}
