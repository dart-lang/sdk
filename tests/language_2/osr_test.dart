// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=5 --no-background-compilation
// Test correct OSR (issue 16151).

import "dart:collection";
import "package:expect/expect.dart";

List create([int length]) {
  return new MyList(length);
}

main() {
  test(create);
}

class MyList<E> extends ListBase<E> {
  List<E> _list;

  MyList([int length])
      : _list = (length == null ? new List() : new List(length));

  E operator [](int index) => _list[index];

  void operator []=(int index, E value) {
    _list[index] = value;
  }

  int get length => _list.length;

  void set length(int newLength) {
    _list.length = newLength;
  }
}

test(List create([int length])) {
  sort_A01_t02_test(create);
}

//  From library co19 sort_A01_t02.

sort_A01_t02_test(List create([int length])) {
  int c(var a, var b) {
    return a < b ? -1 : (a == b ? 0 : 1);
  }

  int maxlen = 7;
  int prevLength = 0;
  for (int length = 1; length < maxlen; ++length) {
    // Check that we are making progress.
    if (prevLength == length) {
      // Cannot use Expect.notEquals since it hides the bug.
      throw "No progress made";
    }
    prevLength = length;
    List a = create(length);
    List expected = create(length);
    for (int i = 0; i < length; ++i) {
      expected[i] = i;
      a[i] = i;
    }

    void swap(int i, int j) {
      var t = a[i];
      a[i] = a[j];
      a[j] = t;
    }

    void check() {
      return;
      // Deleting the code below will throw a RangeError instead of throw above.
      var a_copy = new List(length);
      a_copy.setRange(0, length, a);
      a_copy.sort(c);
    }

    void permute(int n) {
      if (n == 1) {
        check();
      } else {
        for (int i = 0; i < n; i++) {
          permute(n - 1);
          if (n % 2 == 1) {
            swap(0, n - 1);
          } else {
            swap(i, n - 1);
          }
        }
      }
    } //void permute

    permute(length);
  } //for i in 0..length
} // test
