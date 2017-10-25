// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Constants {
  static const PI = 3.14;
  static const foo = 2;
}

class A {
  static const y = 0;
  int x;
  A() : x = 2 {}
  A.named() : x = 4 {}
  A.superC(x) : x = x + 11 {}
  factory A.fac() {
    return new A.named();
  }
}

class B extends A {
  B() : super() {}
  B.named() : super.superC(2) {}
  factory B.fac() {
    return new B.named();
  }
}

class C {
  final int x;
  const C() : x = 2;
  const C.named() : x = 4;
  const C.superC(x) : x = x + 11;
  factory C.fac() {
    return const C.named();
  }
}

class D extends C {
  const D() : super();
  const D.named() : super.superC(2);
  factory D.fac() {
    return const D.named();
  }
}

class E {
  var f;
  E() {}
  E.fun(x)
      : f = (() {
          return x + 13;
        }) {}
  static foo() {
    return 3;
  }

  static fooo(x) {
    return () {
      return x + 1024;
    };
  }

  bar() {
    return 4;
  }

  toto(x) {
    return () {
      return x + 5;
    };
  }
}
