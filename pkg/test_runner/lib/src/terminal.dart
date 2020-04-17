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
