// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

abstract class I<E> {
  String m(a, String f(v, E e));
}

abstract class A<E> implements I<E> {
  const A();
  String m(a, String f(v, E e));
}

abstract class M {
  final int y = 0;
}

class B<E> extends A<E> implements M {
  const B();
  int get y => 0;

  m(a, f(v, E e)) => throw '';
}

foo() {
  // Error:INVALID_ASSIGNMENT
  int y = new /*@typeArgs=dynamic*/ B(). /*@target=B.m*/ m(throw '', throw '');
  String z =
      new /*@typeArgs=dynamic*/ B(). /*@target=B.m*/ m(throw '', throw '');
}

main() {}
