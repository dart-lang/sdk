// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A constructor can't be static.
class A {
  static //# 00: syntax error
  A();
}

// A factory constructor can't be static.
class B {
  static //# 01: syntax error
  factory B() { return null; }
}

// A named constructor can have the same name as a setter.
class E {
  set setter(value) {} //# 05: ok
  E.setter();
}

// A constructor can't be static.
class F {
  static //# 07: compile-time error
  F(){}
}

main() {
  new A();
  new B();
  new E.setter();
  new F();
}
