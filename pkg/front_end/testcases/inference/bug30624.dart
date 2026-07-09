// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

void foo<E>(C<E> c, int cmp(E a, E b)) {}

class C<E> {
  void barA([int Function(E a, E b)? cmp]) {
    foo(this, cmp ?? _default);
  }

  void barB([int Function(E a, E b)? cmp]) {
    foo(this, cmp ?? (_default as int Function(E, E)));
  }

  void barC([int Function(E a, E b)? cmp]) {
    int Function(E, E) v = _default;
    foo(this, cmp ?? v);
  }

  void barD([int Function(E a, E b)? cmp]) {
    foo<E>(this, cmp ?? _default);
  }

  void barE([int Function(E a, E b)? cmp]) {
    foo(this, cmp == null ? _default : cmp);
  }

  void barF([int Function(E a, E b)? cmp]) {
    foo(this, cmp != null ? cmp : _default);
  }

  static int _default(a, b) {
    return -1;
  }
}

main() {}
