import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Load the bundled Nunito and Fredoka fonts before any test runs, so font
/// loading never finishes in the middle of a test.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final weight in [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900,
  ]) {
    GoogleFonts.nunito(fontWeight: weight);
  }
  for (final weight in [FontWeight.w500, FontWeight.w600, FontWeight.w700]) {
    GoogleFonts.fredoka(fontWeight: weight);
  }
  await GoogleFonts.pendingFonts();
  await testMain();
}
