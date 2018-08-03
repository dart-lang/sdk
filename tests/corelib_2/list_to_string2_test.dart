// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  List list = [1, 2];
  list.add(list);

  List list2 = new List(4);
  list2[0] = 1;
  list2[1] = 2;
  list2[2] = list2;
  list2[3] = list;

  Expect.equals("[1, 2, [...]]", list.toString());
  Expect.equals("[1, 2, [...], [1, 2, [...]]]", list2.toString());

  // Throwing in the middle of a toString does not leave the
  // list as being visited.
  List list3 = [1, 2, new ThrowOnToString(), 4];
  Expect.throws(list3.toString, (e) => e == "Bad!");
  list3[2] = 3;
  Expect.equals("[1, 2, 3, 4]", list3.toString());
}

class ThrowOnToString {
  String toString() {
    throw "Bad!";
  }
}
