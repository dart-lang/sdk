// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A constructor can't be static.
class A {
  static
//^^^^^^
// [analyzer] SYNTACTIC_ERROR.STATIC_CONSTRUCTOR
// [cfe] Constructors can't be static.
  A();
  // ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_FUNCTION_BODY
  // [cfe] Expected a function body or '=>'.
}

// A factory constructor can't be static.
class B {
  static
//^^^^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'static' here.
  factory B() { return null; }
}

// A named constructor can have the same name as a setter.
class E {
  set setter(value) {}
  E.setter();
}

// A constructor can't be static.
class F {
  static
//^^^^^^
// [analyzer] SYNTACTIC_ERROR.STATIC_CONSTRUCTOR
// [cfe] Constructors can't be static.
  F(){}
}

main() {
  new A();
  new B();
  new E.setter();
  new F();
}
