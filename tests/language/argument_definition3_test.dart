// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  new Param.test1(false);
  new Param.test1(true, 42);

  new Param.test2(false);
  new Param.test2(true, 42);

  new Param.test3(false);
  new Param.test3(true, 42);

  new Param.test4();
  new Param.test5();

  new Param.test6(false);
  new Param.test6(true, 42);

  new Param.test7();
  new Param.test8();
}

class Super {
  var superField;
  var otherSuperField;

  Super();
  Super.withParameters(passed, op, value) {
    Expect.equals(passed, op);
    Expect.equals(passed ? 42 : 0, value);
  }

  Super.withOptional(passed, [int a]) : superField = ?a {
    Expect.equals(passed, ?a);
    Expect.equals(passed, superField);
  }

  Super.withUpdate(passed, [int a = 0])
      : superField = ?a, otherSuperField = a++ {
    Expect.equals(passed, ?a);
    Expect.equals(passed, superField);
    Expect.equals(passed ? 43 : 1, a);
  }
}

class Param extends Super {
  var field;
  var otherField;

  Param.test1(a_check, [int a]) {
    Expect.equals(a_check, ?a);
  }

  Param.test2(passed, [int a]) : field = ?a {
    Expect.equals(passed, ?a);
    Expect.equals(passed, field);
  }

  Param.test3(passed, [int a = 0]) : super.withParameters(passed, ?a, a) {
    Expect.equals(passed, ?a);
  }

  Param.test4() : super.withOptional(true, 42);
  Param.test5() : super.withOptional(false);

  Param.test6(passed, [int a = 0]) : field = ?a, otherField = a++ {
    Expect.equals(passed, ?a);
    Expect.equals(passed, field);
    Expect.equals(passed ? 43 : 1, a);
  }

  Param.test7() : super.withUpdate(true, 42);
  Param.test8() : super.withUpdate(false);
}
