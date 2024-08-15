// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/language/label/label6_test.dart

void foo() {
  L:
  while (false) {
    break;
    break L;
    void innerFunc() {
      if (true) break L; // Error
    }

    innerFunc();
  }
}
