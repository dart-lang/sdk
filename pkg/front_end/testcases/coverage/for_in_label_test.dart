// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/language/library/env_test.dart

void foo() {
  for(int x in [1, 2, 3, 4]) {
    if (x == 2) continue;
    if (x == 3) break;
    print("Hello $x");
  }
}
