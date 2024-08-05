// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// From tests/co19/src/Language/Statements/Continue/label_t14.dart

void foo() {
  switch (1) {
    L: case 1:
      foo() {
        continue L; // Error
      }
      foo();
  }
}
