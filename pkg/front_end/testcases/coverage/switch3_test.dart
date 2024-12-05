// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/language/switch/switch3_test.dart

/// Check that 'continue' to switch statement is illegal.

void foo() {
  var a = 5;
  var x;
  bar: switch (a) {
    case 1: x = 1; break;
    case 6: x = 2; continue; // Error
    case 8:  break;
  }
  return a;
}
