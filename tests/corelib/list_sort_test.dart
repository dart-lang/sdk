// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("ListSortTest.dart");
#source("sort_helper.dart");

class ListSortTest {
  static void testMain() {
    var compare = (a, b) => a.compareTo(b);
    var sort = (list) => list.sort(compare);
    new SortHelper(sort, compare).run();

    compare = (a, b) => -a.compareTo(b);
    new SortHelper(sort, compare).run();
  }
}

main() {
  ListSortTest.testMain();
}
