// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  const A();
  bool operator ==(Object other) {
    return false;
  }
}

class B {
  bool operator ==(Object other) {
    Expect.fail("Bad equality order.");
  }
}

main() {
  test(iterable) {
    Expect.isFalse(iterable.contains(new B()));
  }

  var iterables = [
    <A>[new A()],
    new List<A>(1)..[0] = new A(),
    new List<A>()..add(new A()),
    const <A>[const A()],
    new Set()..add(new A()),
    (new Map()..[new A()] = 0).keys,
    (new Map()..[0] = new A()).values
  ];

  for (var iterable in iterables) {
    test(iterable);
    test(iterable.map((x) => x));
    test(iterable.take(1));
  }
}
