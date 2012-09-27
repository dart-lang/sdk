// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("GrowableObjectArrayTest.dart");
#import("dart:coreimpl");

class GrowableObjectArrayTest {

  static void testOutOfBoundForIndexOf() {
    GrowableObjectArray<int> array = new GrowableObjectArray<int>();
    for (int i = 0; i < 64; i++) {
      array.add(i);
      Expect.equals(-1, array.indexOf(4, i + 1));
      Expect.equals(-1, array.lastIndexOf(4, -1));
    }
  }

  static testMain() {
    GrowableObjectArray<int> array = new GrowableObjectArray<int>();
    array.add(1);
    array.add(2);
    array.add(3);
    array.add(4);
    array.add(1);

    Expect.equals(3, array.indexOf(4, 0));
    Expect.equals(0, array.indexOf(1, 0));
    Expect.equals(4, array.lastIndexOf(1, array.length - 1));

    Expect.equals(4, array.indexOf(1, 1));
    Expect.equals(-1, array.lastIndexOf(4, 2));

    Expect.equals(5, array.length);

    testMap(int n) => n + 2;

    GrowableObjectArray mapped = array.map(testMap);

    Expect.equals(5, mapped.length);

    Expect.equals(3, mapped[0]);
    Expect.equals(4, mapped[1]);
    Expect.equals(5, mapped[2]);
    Expect.equals(6, mapped[3]);
    Expect.equals(3, mapped[4]);

    Expect.equals(5, array.length);

    Expect.equals(1, array[0]);
    Expect.equals(2, array[1]);
    Expect.equals(3, array[2]);
    Expect.equals(4, array[3]);
    Expect.equals(1, array[4]);

    bool found = false;
    array = array.filter(bool _(e) {
      return found || !(found = (e == 1));
    });

    Expect.equals(4, array.length);

    Expect.equals(2, array[0]);
    Expect.equals(3, array[1]);
    Expect.equals(4, array[2]);
    Expect.equals(1, array[3]);

    Expect.equals(1, array.removeLast());
    Expect.equals(3, array.length);
    Expect.equals(2, array[0]);
    Expect.equals(3, array[1]);
    Expect.equals(4, array[2]);

    Expect.equals(-1, array.indexOf(6, 0));

    array.clear();
    array.add(1);
    array.add(1);
    array.add(1);
    array.add(1);
    array.add(2);

    Expect.equals(5, array.length);
    array = array.filter((e) => e != 1 );
    Expect.equals(1, array.length);
    Expect.equals(2, array[0]);

    // Check correct copy order/
    array = new GrowableObjectArray<int>();
    for (int i = 0; i < 10; i++) {
      array.add(i);
    }
    array.setRange(8, 2, array, 7);
    Expect.equals(7, array[7]);
    Expect.equals(7, array[8]);
    Expect.equals(8, array[9]);
    array.setRange(4, 2, array, 5);
    Expect.equals(5, array[4]);
    Expect.equals(6, array[5]);
    Expect.equals(6, array[6]);

    testOutOfBoundForIndexOf();

    GrowableObjectArray<int> h = new GrowableObjectArray<int>.withCapacity(10);
    List constArray = const [0, 1, 2, 3, 4];
    h.addAll(constArray);
    Expect.equals(5, h.length);
  }
}

main() {
  GrowableObjectArrayTest.testMain();
}
