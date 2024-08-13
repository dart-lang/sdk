// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Foo<T> {
  static final create = <U>(e) => C<U>.filled(e);
}

class C<T> implements I<T>, J<T> {
  final T value;

  C(this.value);

  factory C.filled(T fill) {
    return C<T>(fill);
  }
}

abstract mixin class I<E> {
  I();
}

mixin class J<E> {
  J();
}

void main() {
  var foo1 = Foo.create<int>(42);
  Expect.equals(foo1.value, 42);
  Expect.type<C<int>>(foo1);

  var j = J<J<bool>>();

  var foo2 = Foo.create(j);
  Expect.equals(foo2.value, j);
  Expect.type<C<dynamic>>(foo2);

  var foo3 = Foo.create<J<J<bool>>>(j);
  Expect.equals(foo3.value, j);
  Expect.type<C<J<J<bool>>>>(foo3);
}
