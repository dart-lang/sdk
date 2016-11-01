// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for sort routines.
library sort_test;
import "package:expect/expect.dart";
import 'sort_helper.dart';

main() {
  var compare = (a, b) => a.compareTo(b);
  var sort = (list) => list.sort(compare);
  new SortHelper(sort, compare).run();

  compare = (a, b) => -a.compareTo(b);
  new SortHelper(sort, compare).run();

  compare = (a, b) => a.compareTo(b);

  // Pivot-canditate indices: 7, 15, 22, 29, 37
  // Test dutch flag partitioning (canditates 2 and 4 are the same).
  var list = [0, 0, 0, 0, 0, 0, 0, 0/**/, 0, 0, 0, 0, 0, 0, 0,
              1/**/, 1, 1, 1, 1, 1, 1, 1/**/, 1, 1, 1, 1, 1, 1, 1/**/,
              2, 2, 2, 2, 2, 2, 2, 2/**/, 2, 2, 2, 2, 2, 2, 2];
  list.sort(compare);
  Expect.listEquals(list, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                           1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                           2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);

  list = [0, 0, 0, 0, 0, 0, 0, 1/**/, 0, 0, 0, 0, 0, 0, 0,
          0/**/, 1, 1, 1, 1, 1, 1, 0/**/, 1, 1, 1, 1, 1, 1, 0/**/,
          2/**/, 2, 2, 2, 2, 2, 2, 2/**/, 2, 2, 2, 2, 2, 2, 2];
  list.sort(compare);
  Expect.listEquals(list, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                           0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
                           2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]);

  // Pivots: 1 and 8.
  // The second partition will be big (more than 2/3 of the list), and an
  // optimization kicks in that removes the pivots from the partition.
  list = [0, 9, 0, 9, 3, 9, 0, 1/**/, 1, 0, 1, 9, 8, 2, 1,
          1/**/, 4, 5, 2, 5, 0, 1, 8/**/, 8, 8, 5, 2, 2, 9, 8/**/,
          8, 4, 4, 1, 5, 3, 2, 8/**/, 5, 1, 2, 8, 5, 6, 8];
  list.sort(compare);
  Expect.listEquals(list, [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2,
                           2, 2, 2, 2, 3, 3, 4, 4, 4, 5, 5, 5, 5, 5, 5,
                           6, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9]);
}
