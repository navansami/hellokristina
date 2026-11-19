/// Where a "don't remember me" sign-in lives: the browser tab's
/// sessionStorage on the web (cleared when the tab closes), memory elsewhere
/// (cleared when the app closes). Remembered sign-ins use SharedPreferences.
export 'session_store_io.dart'
    if (dart.library.js_interop) 'session_store_web.dart';
