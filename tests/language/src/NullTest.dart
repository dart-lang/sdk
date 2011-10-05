// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Second dart test program.

class NullTest {
  static int foo(var obj) {
    Expect.equals(null, obj);
  }

  static bool compareToNull(var value) {
    return null == value;
  }

  static bool compareWithNull(var value) {
    return value == null;
  }

  static int testMain() {
    var val = 1;
    var obj = null;

    Expect.equals(null, obj);
    Expect.equals(null, null);

    foo(obj);
    foo(null);

    if (obj != null) {
      foo(null);
    } else {
      foo(obj);
    }

    Expect.isFalse(compareToNull(val));
    Expect.isTrue(compareToNull(obj));
    Expect.isFalse(compareWithNull(val));
    Expect.isTrue(compareWithNull(obj));
    Expect.isTrue(obj is Object);
    Expect.isFalse(obj is String);
    Expect.isTrue(obj is !String);
    Expect.isFalse(obj is !Object);
    Expect.isFalse(val is !Object);

    return 0;
  }
}


main() {
  NullTest.testMain();
}
