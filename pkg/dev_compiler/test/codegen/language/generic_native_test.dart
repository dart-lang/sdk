// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test is-tests with type variables on native subclasses.

import "package:expect/expect.dart";

class A<T> {
  foo(o) => o is T;
}

class B {}

class C {}

main() {
  Expect.isTrue(new A<Iterable<B>>().foo(new List<B>()));
  Expect.isFalse(new A<Iterable<C>>().foo(new List<B>()));

  Expect.isTrue(new A<Pattern>().foo('hest'));

  Expect.isTrue(new A<Comparable<String>>().foo('hest'));
  Expect.isFalse(new A<Comparable<C>>().foo('hest'));
}
