// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  const A();
}

class B extends A {
  const B();
}

main() {
  var set1 = new Set<B>();
  set1.add(const B());
  var set2 = new Set<B>();
  var list = <B>[const B()];
  var set3 = list.toSet();

  var sets = [set1, set2, set3];
  for (var setToTest in sets) {
    // Test that the set accepts a list that is not of the same type:
    //   Set<B>.retainAll(List<A>)
    setToTest.retainAll(<A>[new A()]);
  }
}
