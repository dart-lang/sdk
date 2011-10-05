// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for sort routines.
// VMOptions=--expose_core_impl
#source("SortHelper.dart");

class SortTest {

  static void testMain() {
    var compare = (a, b) => a.compareTo(b);
    var sort = (list) => DualPivotQuicksort.sort(list, compare);
    new SortHelper(sort, compare).run();

    compare = (a, b) => -a.compareTo(b);
    new SortHelper(sort, compare).run();
  }
}

main() {
  SortTest.testMain();
}
