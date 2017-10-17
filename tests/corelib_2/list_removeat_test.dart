// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:collection';

class MyList extends ListBase {
  List list;
  MyList(this.list);

  get length => list.length;
  set length(val) {
    list.length = val;
  }

  operator [](index) => list[index];
  operator []=(index, val) => list[index] = val;

  String toString() => "[" + join(", ") + "]";
}

// l1 must be a modifiable list with 5 elements from 0 to 4.
void testModifiableList(l1) {
  // Index must be integer and in range.
  Expect.throwsRangeError(() => l1.removeAt(-1), "negative");
  Expect.throwsRangeError(() => l1.removeAt(5), "too large");
  Expect.throwsArgumentError(() => l1.removeAt(null), "too large");

  Expect.equals(2, l1.removeAt(2), "l1-remove2");
  Expect.equals(1, l1[1], "l1-1[1]");

  Expect.equals(3, l1[2], "l1-1[2]");
  Expect.equals(4, l1[3], "l1-1[3]");
  Expect.equals(4, l1.length, "length-1");

  Expect.equals(0, l1.removeAt(0), "l1-remove0");
  Expect.equals(1, l1[0], "l1-2[0]");
  Expect.equals(3, l1[1], "l1-2[1]");
  Expect.equals(4, l1[2], "l1-2[2]");
  Expect.equals(3, l1.length, "length-2");
}

void main() {
  // Normal modifiable list.
  testModifiableList([0, 1, 2, 3, 4]);
  testModifiableList(new MyList([0, 1, 2, 3, 4]));

  // Fixed size list.
  var l2 = new List(5);
  for (var i = 0; i < 5; i++) l2[i] = i;
  Expect.throwsUnsupportedError(() => l2.removeAt(2), "fixed-length");

  // Unmodifiable list.
  var l3 = const [0, 1, 2, 3, 4];
  Expect.throwsUnsupportedError(() => l3.removeAt(2), "unmodifiable");

  // Empty list is not special.
  var l4 = [];
  Expect.throwsRangeError(() => l4.removeAt(0), "empty");
}
