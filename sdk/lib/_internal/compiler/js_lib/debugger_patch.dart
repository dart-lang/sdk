// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch file for dart:debugger library.

import 'dart:_js_helper' show patch;
import 'dart:_foreign_helper' show JS;

@patch class Debugger {
  /// Stop the program as if a breakpoint where hit at the following statement.
  /// NOTE: When invoked, the isolate will not return until a debugger
  /// continues execution. When running in the Dart VM the behaviour is the same
  /// regardless of whether or not a debugger is connected. When compiled to
  /// JavaScript, this uses the "debugger" statement, and behaves exactly as
  /// that does.
  @patch
  @ForceInline()
  static void breakHere() {
    JS('', 'debugger');
  }

  /// If [expr] is true, stop the program as if a breakpoint where hit at the
  /// following statement. See [breakHere].
  @patch
  @ForceInline()
  static void breakHereIf(bool expr) {
    if (expr) {
      breakHere();  
    }
  }
}