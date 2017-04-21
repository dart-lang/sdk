// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var list = [];
  list.removeRange(0, 0);
  Expect.equals(0, list.length);
  expectIOORE(() {
    list.removeRange(0, 1);
  });

  list.add(1);
  list.removeRange(0, 0);
  Expect.equals(1, list.length);
  Expect.equals(1, list[0]);

  expectIOORE(() {
    list.removeRange(0, 2);
  });
  Expect.equals(1, list.length);
  Expect.equals(1, list[0]);

  list.removeRange(0, 1);
  Expect.equals(0, list.length);

  list.addAll([3, 4, 5, 6]);
  Expect.equals(4, list.length);
  list.removeRange(0, 4);
  Expect.listEquals([], list);

  list.addAll([3, 4, 5, 6]);
  list.removeRange(2, 4);
  Expect.listEquals([3, 4], list);
  list.addAll([5, 6]);

  expectIOORE(() {
    list.removeRange(4, 5);
  });
  Expect.listEquals([3, 4, 5, 6], list);

  list.removeRange(1, 3);
  Expect.listEquals([3, 6], list);

  testNegativeIndices();
}

void expectIOORE(void f()) {
  Expect.throws(f, (e) => e is RangeError);
}

void testNegativeIndices() {
  var list = [1, 2];
  expectIOORE(() {
    list.removeRange(-1, 1);
  });
  Expect.listEquals([1, 2], list);

  // A negative length throws an ArgumentError.
  expectIOORE(() {
    list.removeRange(0, -1);
  });
  Expect.listEquals([1, 2], list);

  expectIOORE(() {
    list.removeRange(-1, -1);
  });
  Expect.listEquals([1, 2], list);

  expectIOORE(() {
    list.removeRange(-1, 0);
  });

  expectIOORE(() {
    list.removeRange(4, 4);
  });
  Expect.listEquals([1, 2], list);
}
