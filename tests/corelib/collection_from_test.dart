// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CollectionFromTest {
  static testMain() {
    var set = new Set<int>();
    set.add(1);
    set.add(2);
    set.add(4);
    check(set, new List<int>.from(set));
    check(set, new List.from(set));
    check(set, new Queue<int>.from(set));
    check(set, new Queue.from(set));
    check(set, new Set<int>.from(set));
    check(set, new Set.from(set));
  }


  static check(Collection initial, Collection other) {
    Expect.equals(3, initial.length);
    Expect.equals(initial.length, other.length);

    int initialSum = 0;
    int otherSum = 0;

    initial.forEach(void f(e) { initialSum += e; });
    other.forEach(void f(e) { otherSum += e; });
    Expect.equals(4 + 2 + 1, otherSum);
    Expect.equals(otherSum, initialSum);
  }
}

main() {
  CollectionFromTest.testMain();
}
