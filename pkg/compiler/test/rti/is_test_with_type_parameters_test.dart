// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

// Tests that is-tests are also available for superclasses if the class is
// never instantiated and not explicitly tested against.

class A {}

class B extends A {}

class C<T> implements A {}

class D<T, L> {}

class F {}

class E<T, L> extends D<L, T> {}

class G extends F {}

main() {
  var l = [new A(), new B(), new C<E<G, G>>()];
  Expect.isTrue(l[0] is A);
  Expect.isTrue(l[1] is B);
  Expect.isTrue(l[2] is C<D<F, G>>);
  for (int i = 0; i < l.length; i++) {
    var e = l[i];
    Expect.isTrue(e is A);
    Expect.equals(e is B, i == 1);
    Expect.isFalse(e is C<String>);
    Expect.equals(e is C<D<F, G>>, i == 2);
  }
}
