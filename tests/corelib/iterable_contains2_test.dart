// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests for the contains methods on lists.

class A {
  const A();
}

class B extends A {
  const B();
}

main() {
  var list = <B>[new B()];
  var set = new Set<B>();
  set.add(new B());
  var iterable1 = list.map((x) => x);
  var iterable2 = list.take(1);
  var list2 = const <B>[const B()];
  var iterable3 = list2.map((x) => x);
  var iterable4 = list2.take(1);
  var iterables = [
    list,
    set,
    iterable1,
    iterable2,
    list2,
    iterable3,
    iterable4
  ];
  for (var iterable in iterables) {
    Expect.isFalse(iterable.contains(new A()));
  }
}
