// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class ListIteratorsTest {
  static void checkListIterator(List a) {
    Iterator it = a.iterator;
    Expect.isNull(it.current);
    for (int i = 0; i < a.length; i++) {
      Expect.isTrue(it.moveNext());
      var elem = it.current;
      Expect.equals(a[i], elem);
    }
    Expect.isFalse(it.moveNext());
    Expect.isNull(it.current);
  }

  static testMain() {
    checkListIterator([]);
    checkListIterator([1, 2]);
    checkListIterator(new List(0));
    checkListIterator(new List(10));
    checkListIterator(new List());
    List g = new List();
    g.addAll([1, 2, 3]);
    checkListIterator(g);

    // This is mostly undefined behavior.
    Iterator it = g.iterator;
    Expect.isTrue(it.moveNext());
    Expect.equals(1, it.current);
    Expect.isTrue(it.moveNext());
    g[1] = 49;
    // The iterator keeps the last value.
    Expect.equals(2, it.current);
    Expect.isTrue(it.moveNext());
    g.removeLast();
    // The iterator keeps the last value.
    Expect.equals(3, it.current);
    Expect.throws(it.moveNext, (e) => e is ConcurrentModificationError);
    // No progress when throwing.
    Expect.equals(3, it.current);
  }
}

main() {
  ListIteratorsTest.testMain();
}
