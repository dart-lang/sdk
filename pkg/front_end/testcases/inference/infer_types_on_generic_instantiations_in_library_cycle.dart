// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'infer_types_on_generic_instantiations_in_library_cycle_a.dart';

abstract class A<E> implements I<E> {
  const A();

  final E value = null;
}

abstract class M {
  final int y = 0;
}

class B<E> extends A<E> implements M {
  const B();
  int get y => 0;

  /*@topType=A<B::E>*/ m(/*@topType=dynamic*/ a, f(v, int e)) {}
}

foo() {
  int y = /*error:INVALID_ASSIGNMENT*/ new B<String>()
      . /*@target=B::m*/ m(null, null)
      . /*@target=A::value*/ value;
  String z = new B<String>()
      . /*@target=B::m*/ m(null, null)
      . /*@target=A::value*/ value;
}

main() {}
