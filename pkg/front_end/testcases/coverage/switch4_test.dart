// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/language/switch/switch4_test.dart

/// Discover unresolved case labels.

void foo() {
  var a = 5;
  var x;
  switch (a) {
    case 1:
      x = 1;
      continue L; // Error
    case 6:
      x = 2;
      break;
    case 8:
      break;
  }
  return a;
}
