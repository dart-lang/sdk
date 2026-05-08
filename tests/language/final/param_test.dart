// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Limit language version to a pre-primary constructors version.
// @dart = 3.11

// Disallow assignment of parameters marked as final.

class A {
  static void test(final x) {
    x = 2;
    // [error column 5, length 1]
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
    // [cfe] Can't assign to the final variable 'x'.
  }
}

main() {
  A.test(1);
}
