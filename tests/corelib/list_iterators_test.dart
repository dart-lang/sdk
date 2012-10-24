// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ListIteratorsTest {
  static void checkListIterator(List a) {
    Iterator it = a.iterator();
    Expect.equals(false, it.hasNext == a.isEmpty);
    for (int i = 0; i < a.length; i++) {
      Expect.equals(true, it.hasNext);
      var elem = it.next();
    }
    Expect.equals(false, it.hasNext);
    bool exceptionCaught = false;
    try {
     var eleme = it.next();
    } on NoMoreElementsException catch (e) {
     exceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
  }

  static testMain() {
    checkListIterator([]);
    checkListIterator([1, 2]);
    checkListIterator(new List(0));
    checkListIterator(new List(10));
    checkListIterator(new List());
    List g = new List();
    g.addAll([1, 2]);
    checkListIterator(g);

    Iterator it = g.iterator();
    Expect.equals(true, it.hasNext);
    g.removeLast();
    Expect.equals(true, it.hasNext);
    g.removeLast();
    Expect.equals(false, it.hasNext);

    g.addAll([10, 20]);
    int sum = 0;
    for (var elem in g) {
      sum += elem;
      // Iterator must realize that g has no more elements.
      g.removeLast();
    }
    Expect.equals(10, sum);
  }
}

main() {
  ListIteratorsTest.testMain();
}
