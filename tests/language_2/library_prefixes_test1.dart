// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of LibraryPrefixesTest1.lib;

class Constants {
  static const PI = 3.14;
  static const foo = 1;
}

class A {
  static const y = -1;
  int x;
  A() : x = 1 {}
  A.named() : x = 3 {}
  A.superC(x) : x = x + 7 {}
  factory A.fac() {
    return new A.named();
  }
}

class B extends A {
  B() : super() {}
  B.named() : super.superC(1) {}
  factory B.fac() {
    return new B.named();
  }
}

class C {
  final int x;
  const C() : x = 1;
  const C.named() : x = 3;
  const C.superC(x) : x = x + 7;
  factory C.fac() {
    return const C.named();
  }
}

class D extends C {
  const D() : super();
  const D.named() : super.superC(1);
  factory D.fac() {
    return const D.named();
  }
}

class E {
  var f;
  E() {}
  E.fun(x)
      : f = (() {
          return x + 11;
        }) {}
  static foo() {
    return 0;
  }

  static fooo(x) {
    return () {
      return x + 99;
    };
  }

  bar() {
    return 1;
  }

  toto(x) {
    return () {
      return x + 2;
    };
  }
}
