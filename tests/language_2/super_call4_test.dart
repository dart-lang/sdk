// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Checks that noSuchMethod is resolved in the super class and not in the
// current class.

class C {
  E e = new E();

  bool foo();
  bool bar(int a);
  bool baz({int b});
  bool boz(int a, {int c});

  bool noSuchMethod(Invocation im) => true;
}

class D extends C {
  bool noSuchMethod(Invocation im) => false;

  test1() {
    return super.foo(); //# 01: compile-time error
  }

  test2() {
    return super.bar(1); //# 01: compile-time error
  }

  test3() {
    return super.baz(b: 2); //# 01: compile-time error
  }

  test4() {
    return super.boz(1, c: 2); //# 01: compile-time error
  }
}

class E {
  bool foo() => true;
  bool bar(int a) => a == 1;
  bool baz({int b}) => b == 2;
  bool boz(int a, {int c}) => a == 1 && c == 2;
}

main() {
  var d = new D();
  Expect.isNull(d.test1());
  Expect.isNull(d.test2());
  Expect.isNull(d.test3());
  Expect.isNull(d.test4());
}
