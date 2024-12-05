// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/co19/src/Language/Statements/Continue/label_t03.dart

void foo() {
  var counter = 0;
  L: while (counter < 7) {
    counter++;
    if (counter == 3) {
      foo() {
        continue L; // Error
      }
      foo();
    }
  }
}
