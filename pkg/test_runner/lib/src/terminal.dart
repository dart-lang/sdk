// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

// TODO(rnystrom): Move all print calls to go through this. Unify with DebugLog.
/// Interface for the test runner printing output to the user.
///
/// It mainly exists to gracefully handle the inline progress indicator:
///
///     [00:08 | 100% | +  139 | -    3]
///
/// That does not print a newline at the end, but subsequent output should
/// insert the newline before writing itself. This tracks whether that needs to
/// be done.
class Terminal {
  static bool _needsNewline = false;

  /// Prints [obj] to its own line.
  ///
  /// If this is called after a call to [writeLine], prints a newline first to
  /// end that earlier line.
  static void print(Object obj) {
    finishLine();
    stdout.writeln(obj);
  }

  /// Overwrites the current line with [obj].
  ///
  /// Does not output a newline at the end.
  static void writeLine(Object obj) {
    stdout.write('\r$obj');
    _needsNewline = true;
  }

  /// If the last output was from [writeLine], finishes it by writing a newline.
  static void finishLine() {
    if (_needsNewline) stdout.writeln();
    _needsNewline = false;
  }
}

/// The maximum line length for output.
///
/// If the test runner isn't attached to a terminal, defaults to 80 columns.
final int _lineLength = () {
  try {
    return stdout.terminalColumns;
  } on StdoutException {
    return 80;
  }
}();

/// Wraps [text] so that it fits within [_lineLength], if there is a line length.
///
/// This preserves existing newlines and only splits words on spaces, not on
/// other sorts of whitespace or separators.
///
/// If [prefix] is passed, it's added at the beginning of any wrapped lines.
String wordWrap(String text, {String prefix}) {
  prefix ??= '';

  var buffer = StringBuffer();
  var originalLines = text.split('\n');
  var lengthSoFar = 0;
  var needsNewline = false;
  var needsSpace = false;

  for (var i = 0; i < originalLines.length; i++) {
    var originalLine = originalLines[i];
    for (var word in originalLine.split(' ')) {
      // If this word would push us over, split before it.
      if (lengthSoFar + 1 + word.length > _lineLength) needsNewline = true;

      if (needsNewline) {
        buffer.writeln();
        buffer.write(prefix);
        lengthSoFar = prefix.length;
        needsSpace = false;
      } else if (needsSpace) {
        buffer.write(' ');
        lengthSoFar++;
      }

      buffer.write(word);
      lengthSoFar += word.length;

      // If the single word fills the entire line, we need to wrap after it too.
      needsNewline = lengthSoFar > _lineLength;
      needsSpace = !needsNewline;
    }

    if (needsNewline) buffer.writeln();
    needsNewline = true;
  }

  return buffer.toString();
}
