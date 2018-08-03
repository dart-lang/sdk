// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

// The `value` parameter for `B::x=` has a type, so it should not be inferred
// based on `A::x=`.

typedef int F();

abstract class A {
  void set x(F value);
}

abstract class B extends A {
  void set x(value());
}

T f<T>() => null;

g(B b) {
  b. /*@target=B::x*/ x = /*@typeArgs=() -> dynamic*/ f();
}

main() {}
