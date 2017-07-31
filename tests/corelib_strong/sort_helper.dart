// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sort_helper;

import "package:expect/expect.dart";

class SortHelper {
  SortHelper(this.sortFunction, this.compareFunction) {}

  void run() {
    testSortIntLists();
    testSortDoubleLists();
  }

  bool isSorted(List a) {
    for (int i = 1; i < a.length; i++) {
      if (compareFunction(a[i - 1], a[i]) > 0) {
        return false;
      }
    }
    return true;
  }

  void testSortIntLists() {
    var a = new List<int>(40);

    for (int i = 0; i < a.length; i++) {
      a[i] = i;
    }
    testSort(a);

    for (int i = 0; i < a.length; i++) {
      a[a.length - i - 1] = i;
    }
    testSort(a);

    for (int i = 0; i < 21; i++) {
      a[i] = 1;
    }
    for (int i = 21; i < a.length; i++) {
      a[i] = 2;
    }
    testSort(a);

    // Same with bad pivot-choices.
    for (int i = 0; i < 21; i++) {
      a[i] = 1;
    }
    for (int i = 21; i < a.length; i++) {
      a[i] = 2;
    }
    a[6] = 1;
    a[13] = 1;
    a[19] = 1;
    a[25] = 1;
    a[33] = 2;
    testSort(a);

    for (int i = 0; i < 21; i++) {
      a[i] = 2;
    }
    for (int i = 21; i < a.length; i++) {
      a[i] = 1;
    }
    testSort(a);

    // Same with bad pivot-choices.
    for (int i = 0; i < 21; i++) {
      a[i] = 2;
    }
    for (int i = 21; i < a.length; i++) {
      a[i] = 1;
    }
    a[6] = 2;
    a[13] = 2;
    a[19] = 2;
    a[25] = 2;
    a[33] = 1;
    testSort(a);

    var a2 = new List<int>(0);
    testSort(a2);

    var a3 = new List<int>(1);
    a3[0] = 1;
    testSort(a3);

    // --------
    // Test insertion sort.
    testInsertionSort(0, 1, 2, 3);
    testInsertionSort(0, 1, 3, 2);
    testInsertionSort(0, 3, 2, 1);
    testInsertionSort(0, 3, 1, 2);
    testInsertionSort(0, 2, 1, 3);
    testInsertionSort(0, 2, 3, 1);
    testInsertionSort(1, 0, 2, 3);
    testInsertionSort(1, 0, 3, 2);
    testInsertionSort(1, 2, 3, 0);
    testInsertionSort(1, 2, 0, 3);
    testInsertionSort(1, 3, 2, 0);
    testInsertionSort(1, 3, 0, 2);
    testInsertionSort(2, 0, 1, 3);
    testInsertionSort(2, 0, 3, 1);
    testInsertionSort(2, 1, 3, 0);
    testInsertionSort(2, 1, 0, 3);
    testInsertionSort(2, 3, 1, 0);
    testInsertionSort(2, 3, 0, 1);
    testInsertionSort(3, 0, 1, 2);
    testInsertionSort(3, 0, 2, 1);
    testInsertionSort(3, 1, 2, 0);
    testInsertionSort(3, 1, 0, 2);
    testInsertionSort(3, 2, 1, 0);
    testInsertionSort(3, 2, 0, 1);
  }

  void testSort(List a) {
    sortFunction(a);
    Expect.isTrue(isSorted(a));
  }

  void testInsertionSort(int i1, int i2, int i3, int i4) {
    var a = new List<int>(4);
    a[0] = i1;
    a[1] = i2;
    a[2] = i3;
    a[3] = i4;
    testSort(a);
  }

  void testSortDoubleLists() {
    var a = new List<double>(40);
    for (int i = 0; i < a.length; i++) {
      a[i] = 1.0 * i + 0.5;
    }
    testSort(a);

    for (int i = 0; i < a.length; i++) {
      a[i] = 1.0 * (a.length - i) + 0.5;
    }
    testSort(a);

    for (int i = 0; i < a.length; i++) {
      a[i] = 1.5;
    }
    testSort(a);
  }

  Function sortFunction;
  Function compareFunction;
}
