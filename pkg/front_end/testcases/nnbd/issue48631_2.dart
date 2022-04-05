// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

abstract class A {
  T foo<T>(B<T> b);
}

class B<X> {
  B(X x);
}

class C<Y> {
  final Bar<FutureOr<Y>, D<Y>> bar;

  C(this.bar);
}

abstract class D<W> implements A {}

typedef Bar<V, U extends A> = V Function(U);

final baz = C<int>((a) {
    return a.foo(B(Future.value(0)));
});

main() {}
