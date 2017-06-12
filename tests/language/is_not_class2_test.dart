// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for catch that we expect a class after an 'is'. 'aa' is a
// malformed type and a type error should be thrown upon test.

import 'package:expect/expect.dart';

class A {
  const A();
}

class IsNotClass2NegativeTest {
  static testMain() {
    var a = new A();
    var aa = new A();

    if (a is aa) {
      // static warning
      return 0;
    }
    return 0;
  }
}

main() {
  Expect.throws(IsNotClass2NegativeTest.testMain, (e) => e is TypeError);
}
