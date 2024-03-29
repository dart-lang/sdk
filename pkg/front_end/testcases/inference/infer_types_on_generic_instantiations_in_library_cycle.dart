// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'infer_types_on_generic_instantiations_in_library_cycle_a.dart';

abstract class A<E> implements I<E> {
  final E value = throw '';
}

abstract class M {
  final int y = 0;
}

class B<E> extends A<E> implements M {
  int get y => 0;

  m(a, f(v, int e)) => throw '';
}

foo() {
  int y = new B<String>()
      . /*@target=B.m*/ m(throw '', throw '')
      // Error:INVALID_ASSIGNMENT
      . /*@target=A.value*/ value;
  String z = new B<String>()
      . /*@target=B.m*/ m(throw '', throw '')
      . /*@target=A.value*/ value;
}

main() {}
