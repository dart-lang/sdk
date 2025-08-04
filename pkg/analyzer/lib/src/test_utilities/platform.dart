// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// The EOL being used for file content in the current test run.
String get testEol =>
    // TODO(dantup): Support overridding this with an env var to allow testing
    //  `\n` on Windows or `\r\n` on non-Windows, to ensure we don't have any
    //  code just assuming the platform EOL (instead of the files EOL).
    Platform.lineTerminator;

/// Normalizes content to use platform-specific newlines.
///
/// This ensures that when running on Windows, '\r\n' is used, even though
/// source files are checked out using '\n'.
String normalizeNewlinesForPlatform(String input) {
  // Skip normalising for other platforms, as the 'gitattributes' for the Dart
  // SDK ensures all files are '\n'.
  if (!Platform.isWindows) {
    return input;
  }

  var newlinePattern = RegExp(r'\r?\n'); // Either '\r\n' or '\n'.
  return input.replaceAll(newlinePattern, testEol);
}
