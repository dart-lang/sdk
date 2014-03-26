// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_lib.foo;

import 'test_lib.dart';

/**
 * Doc comment for class [B].
 *
 * Multiline Test
 */

/*
 * Normal comment for class B.
 */
class B extends A {

  B();
  B.fooBar();

  /**
   * Test for linking to super
   */
  int doElse(int b) {
    print(b);
    return b;
  }

  /**
   * Test for linking to parameter [c]
   */
  void doThis(int c) {
    print(c);
  }
}

int testFunc(int a) {
  return a;
}
