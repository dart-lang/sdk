// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo(a, [b]) {
}

bar(a, {b}) {
}

class A {
  A();
  A.test(a, [b]);
}

class B {
  B()
    : super.test(b: 1)  /// 01: runtime error
  ;
}

class C extends A {
  C()
    : super.test(b: 1)  /// 02: runtime error
  ;
}

class D {
  D();
  D.test(a, {b});
}

class E extends D {
  E()
    : super.test(b: 1)  /// 05: runtime error
  ;
}

main() {
  new A.test(b: 1);  /// 00: runtime error
  new B();
  new C();
  new D.test(b: 1);  /// 03: runtime error
  new E();
  foo(b: 1);  /// 06: runtime error
  bar(b: 1);  /// 07: runtime error
}
