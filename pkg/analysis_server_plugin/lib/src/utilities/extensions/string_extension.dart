// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension StringExtension on String {
  // This extension is duplicated in analyzer_plugin.

  /// Computes the line ending sequence used in this string.
  ///
  /// Returns the first EOL sequence (`\r\n` or `\n`) found in the content.
  /// If the content contains no EOL sequences, returns null.
  String? get endOfLine {
    var indexOfNewline = indexOf('\n');
    if (indexOfNewline < 0) {
      // No `\n` (and thus no `\r\n` either) found.
      return null;
    }

    if (indexOfNewline > 0 && codeUnitAt(indexOfNewline - 1) == 13 /* \r */) {
      return '\r\n';
    }
    return '\n';
  }
}
