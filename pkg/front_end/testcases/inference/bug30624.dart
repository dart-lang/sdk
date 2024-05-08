// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void foo<E>(C<E> c, int cmp(E a, E b)) {}

class C<E> {
  void barA([int Function(E a, E b)? cmp]) {
    /*@typeArgs=C::E%*/ foo(this, cmp ?? _default);
  }

  void barB([int Function(E a, E b)? cmp]) {
    /*@typeArgs=C::E%*/ foo(this, cmp ?? (_default as int Function(E, E)));
  }

  void barC([int Function(E a, E b)? cmp]) {
    int Function(E, E) v = _default;
    /*@typeArgs=C::E%*/ foo(this, cmp ?? v);
  }

  void barD([int Function(E a, E b)? cmp]) {
    foo<E>(this, cmp ?? _default);
  }

  void barE([int Function(E a, E b)? cmp]) {
    /*@typeArgs=C::E%*/ foo(this,
        cmp == null ? _default : /*@promotedType=(C::E%, C::E%) -> int*/ cmp);
  }

  void barF([int Function(E a, E b)? cmp]) {
    /*@typeArgs=C::E%*/ foo(this,
        cmp != null ? /*@promotedType=(C::E%, C::E%) -> int*/ cmp : _default);
  }

  static int _default(a, b) {
    return /*@target=int.unary-*/ -1;
  }
}

main() {}
