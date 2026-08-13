// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library list_sort_test;

import 'sort_helper.dart';

class ListSortTest {
  static void testMain() {
    var compare = Comparable.compare;
    var sort = (List<num> list) => list.sort(compare);
    new SortHelper(sort, compare).run();

    new SortHelper((List<num> list) => list.sort(), compare).run();

    compare = (a, b) => -a.compareTo(b);
    new SortHelper(sort, compare).run();
  }
}

main() {
  ListSortTest.testMain();
}
