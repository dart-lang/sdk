// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A<T> {
  T x;
}

class B<E> extends A<E> {
  E y;
  get /*@topType=B::E*/ x => /*@target=B::y*/ y;
}

foo() {
  int y = /*error:INVALID_ASSIGNMENT*/ new B<String>(). /*@target=B::x*/ x;
  String z = new B<String>(). /*@target=B::x*/ x;
}

main() {
  foo();
}
