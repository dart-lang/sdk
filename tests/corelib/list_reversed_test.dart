// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


main() {
  testOperations();
}

void testOperations() {
  // Comparison lists.
  List l = const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  List r = const [10, 9, 8, 7, 6, 5, 4, 3, 2, 1];
  // A base list that starts out like l.
  List base = l.toList();
  // A lazy reverse of base.
  List reversed = base.reversed;

  Expect.listEquals(r, reversed);
  Expect.listEquals(l, reversed.reversed);
  for (int i = 0; i < r.length; i++) {
    Expect.equals(r[i], reversed[i]);
  }
  Expect.equals(4, base.indexOf(5));
  Expect.equals(5, reversed.indexOf(5));

  // Combinations of start and end relative to start/end of list.
  List subr = [8, 7, 6, 5, 4, 3];
  Expect.listEquals(subr, reversed.skip(2).take(6));
  Expect.listEquals(subr, reversed.take(8).skip(2));
  Expect.listEquals(subr, reversed.reversed.skip(2).take(6).reversed);
  Expect.listEquals(subr, reversed.reversed.take(8).skip(2).reversed);
  Expect.listEquals(subr, reversed.take(8).reversed.take(6).reversed);
  Expect.listEquals(subr, reversed.reversed.take(8).reversed.take(6));
  Expect.listEquals(subr, reversed.reversed.skip(2).reversed.skip(2));
  Expect.listEquals(subr, reversed.skip(2).reversed.skip(2).reversed);

  // Reverse const list.
  Expect.listEquals(r, l.reversed);
}
