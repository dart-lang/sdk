// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class ContextArgsWithDefaultsTest {
  static void testMain() {
    crasher(1, 'foo')();
  }

  static crasher(int fixed, [String optional = '']) {
    return () {
      Expect.equals(1, fixed);
      Expect.equals('foo', optional);
    };
  }
}

main() {
  ContextArgsWithDefaultsTest.testMain();
}
