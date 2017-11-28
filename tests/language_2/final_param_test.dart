// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Disallow assignment of parameters marked as final.

class A {
  static void test(final x) {
    x = 2; /*@compile-error=unspecified*/
  }
}

main() {
  A.test(1);
}
