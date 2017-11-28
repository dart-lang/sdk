// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A constructor can't be static.
class A {
  static //# 00: compile-time error
  A();
}

// A factory constructor can't be static.
class B {
  static //# 01: syntax error
  factory B() { return null; }
}

// A named constructor can't have the same name as a field.
class C {
  var field;
  C
      .field //# 04: compile-time error
      ();
  C.good();
}

// A named constructor can't have the same name as a method.
class D {
  method() {}
  D
      .method //# 06: compile-time error
      ();
  D.good();
}

// A named constructor can have the same name as a setter.
class E {
  set setter(value) {} //# 05: ok
  E.setter();
}

main() {
  new A();
  new B();
  new C.good();
  new D.good();
  new E.setter();
}
