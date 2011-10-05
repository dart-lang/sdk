// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ListFromListTest {

  static testMain() {
    var list = [1, 2, 4];

    var sub = new List.fromList(list, 0, 3);
    Expect.equals(3, sub.length);
    Expect.equals(1, sub[0]);
    Expect.equals(2, sub[1]);
    Expect.equals(4, sub[2]);

    sub = new List.fromList(list, 1, 3);
    Expect.equals(2, sub.length);
    Expect.equals(2, sub[0]);
    Expect.equals(4, sub[1]);

    sub = new List.fromList(list, 2, 3);
    Expect.equals(1, sub.length);
    Expect.equals(4, sub[0]);

    sub = new List.fromList(list, 0, 0);
    Expect.equals(0, sub.length);

    sub = new List.fromList(list, 3, 3);
    Expect.equals(0, sub.length);

    sub = new List.fromList(list, 0, 1);
    Expect.equals(1, sub.length);
    Expect.equals(1, sub[0]);

    sub = new List.fromList(list, 0, 2);
    Expect.equals(2, sub.length);
    Expect.equals(1, sub[0]);
    Expect.equals(2, sub[1]);

    sub = new List.fromList(list, 1, 2);
    Expect.equals(1, sub.length);
    Expect.equals(2, sub[0]);

    sub = new List.fromList(list, -1, 2);
    Expect.equals(2, sub.length);
    Expect.equals(1, sub[0]);
    Expect.equals(2, sub[1]);

    sub = new List.fromList(list, 1, 5);
    Expect.equals(2, sub.length);
    Expect.equals(2, sub[0]);
    Expect.equals(4, sub[1]);

    list = [];
    sub = new List.fromList(list, 1, 5);
    Expect.equals(0, sub.length);

    sub = new List.fromList(list, 0, 0);
    Expect.equals(0, sub.length);

    sub = new List.fromList(list, 0, 1);
    Expect.equals(0, sub.length);

    // Test that the original list is unchanged after modifications
    // to the list.
    list = [1, 2, 4];
    sub = new List.fromList(list, 0, 3);
    sub[0] = 42;
    Expect.equals(1, list[0]);
    Expect.equals(42, sub[0]);

    sub.add(42);
    Expect.equals(4, sub.length);
    Expect.equals(3, list.length);

    list.add(43);
    Expect.equals(4, sub.length);
    Expect.equals(4, list.length);

    Expect.equals(42, sub[3]);
    Expect.equals(43, list[3]);
  }
}

main() {
  ListFromListTest.testMain();
}
