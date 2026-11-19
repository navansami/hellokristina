/// While a lesson is in progress, ask the browser to warn before the tab is
/// closed or reloaded. Does nothing outside the web.
export 'leave_guard_io.dart'
    if (dart.library.js_interop) 'leave_guard_web.dart';
