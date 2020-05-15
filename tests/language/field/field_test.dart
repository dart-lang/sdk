// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing setting/getting of instance fields.

import "package:expect/expect.dart";

class First {
  First() {}
  var a;
  var b;

  addFields() {
    return a + b;
  }

  setValues() {
    a = 24;
    b = 10;
    return a + b;
  }
}

class Second extends First {
  var c;
  get a {
    return -12;
  }

  set b(a) {
    a.c = 12;
  }
}

class FieldInitializedToNull {
  int? x, y;

  static void test() {
    var f = new FieldInitializedToNull();
    int? missingArg([int? x = 42]) => x;
    Expect.isNull(f.x);
    Expect.isNull(f.y);
    // Regression tests for a DDC bug, where undefined gets initialized in the
    // fields, and is incorrect recognized as a missing argument.
    Expect.isNull(missingArg(f.x));
    Expect.isNull(missingArg(f.y));
  }
}

class FieldTest {
  static one() {
    var f = new First();
    f.a = 3;
    f.b = f.a;
    Expect.equals(3, f.a);
    Expect.equals(f.a, f.b);
    f.b = (f.a = 10);
    Expect.equals(10, f.a);
    Expect.equals(10, f.b);
    f.b = f.a = 15;
    Expect.equals(15, f.a);
    Expect.equals(15, f.b);
    Expect.equals(30, f.addFields());
    Expect.equals(34, f.setValues());
    Expect.equals(24, f.a);
    Expect.equals(10, f.b);
  }

  static two() {
    // The tests below are a little cumbersome because not
    // everything is implemented yet.
    var o = new Second();
    // 'a' getter is overridden, always returns -12.
    Expect.equals(-12, o.a);
    o.a = 2;
    Expect.equals(-12, o.a);
    // 'b' setter is overridden to write 12 to field 'c'.
    o.b = o;
    Expect.equals(12, o.c);
  }
}

main() {
  FieldTest.one();
  FieldTest.two();
  FieldInitializedToNull.test();
}
