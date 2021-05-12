// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for bug in dart2js type promotion.

import 'package:expect/expect.dart';

staticMethod(a) => true;

class Super {
  superMethod(a) => true;
}

class Class extends Super {
  instanceMethod(a) => true;

  test1(c) {
    if (super.superMethod(c is Class2)) {
      return c.method();
    }
    return 0;
  }

  test2(c) {
    if (this.instanceMethod(c is Class2)) {
      return c.method();
    }
    return 0;
  }
}

class Class1 {
  method() => 87;
}

class Class2 {
  method() => 42;
}

test(c) {
  if (staticMethod(c is Class2)) {
    return c.method();
  }
  return 0;
}

main() {
  Expect.equals(87, test(new Class1())); //# 01: ok
  Expect.equals(42, test(new Class2()));

  Expect.equals(87, new Class().test1(new Class1())); //# 02: ok
  Expect.equals(42, new Class().test1(new Class2()));

  Expect.equals(87, new Class().test2(new Class1())); //# 03: ok
  Expect.equals(42, new Class().test2(new Class2()));
}
