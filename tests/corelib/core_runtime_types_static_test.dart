// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

/**
 * Verify static compilation errors on strings and lists.
 */
class CoreStaticTypesTest {
  static testMain() {
    testStringOperators();
    testStringMethods();
    testListOperators();
  }

  static testStringOperators() {
    var q = "abcdef";
    /*@compile-error=unspecified*/ q['hello'];
    /*@compile-error=unspecified*/ q[0] = 'x';
  }

  static testStringMethods() {
    var s = "abcdef";
    /*@compile-error=unspecified*/ s.startsWith(1);
    /*@compile-error=unspecified*/ s.endsWith(1);
  }

  static testListOperators() {
    var a = [1, 2, 3, 4];
    /*@compile-error=unspecified*/ a['0'];
    /*@compile-error=unspecified*/ a['0'] = 99;
  }
}

main() {
  CoreStaticTypesTest.testMain();
}
