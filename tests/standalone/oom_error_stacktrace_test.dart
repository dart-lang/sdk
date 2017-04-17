// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing throw statement
// VMOptions=--old_gen_heap_size=512

import "package:expect/expect.dart";

class Helper1 {
  static int func1() {
    return func2();
  }

  static int func2() {
    return func3();
  }

  static int func3() {
    return func4();
  }

  static int func4() {
    var i = 0;
    try {
      i = 10;
      func5();
    } on OutOfMemoryError catch (e) {
      i = 100;
      Expect.isNull(e.stackTrace, "OOM should not have a stackTrace on throw");
    }
    return i;
  }

  static List func5() {
    // Cause an OOM(out of memory) exception.
    var l1 = new List(268435455);
    return l1;
  }
}

class OOMErrorStackTraceTest {
  static testMain() {
    Expect.equals(100, Helper1.func1());
  }
}

main() {
  OOMErrorStackTraceTest.testMain();
}
