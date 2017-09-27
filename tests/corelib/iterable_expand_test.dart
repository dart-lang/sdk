// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
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

main() {
  test(expectation, iterable) {
    Expect.listEquals(expectation, iterable.toList());
  }

  // Function not called on empty iterable.
  test(
      [],
      [].expand((x) {
        throw "not called";
      }));

  // Creating the iterable doesn't call the function.
  [1].expand((x) {
    throw "not called";
  });

  test([1], [1].expand((x) => [x]));
  test([1, 2, 3], [1, 2, 3].expand((x) => [x]));

  test([], [1].expand((x) => []));
  test([], [1, 2, 3].expand((x) => []));
  test([2], [1, 2, 3].expand((x) => x == 2 ? [2] : []));

  test([1, 1, 2, 2, 3, 3], [1, 2, 3].expand((x) => [x, x]));
  test([1, 1, 2], [1, 2, 3].expand((x) => [x, x, x].skip(x)));

  test([1], new MyList([1]).expand((x) => [x]));
  test([1, 2, 3], new MyList([1, 2, 3]).expand((x) => [x]));

  test([], new MyList([1]).expand((x) => []));
  test([], new MyList([1, 2, 3]).expand((x) => []));
  test([2], new MyList([1, 2, 3]).expand((x) => x == 2 ? [2] : []));

  test([1, 1, 2, 2, 3, 3], new MyList([1, 2, 3]).expand((x) => [x, x]));
  test([1, 1, 2], new MyList([1, 2, 3]).expand((x) => [x, x, x].skip(x)));

  // if function throws, iteration is stopped.
  Iterable iterable = [1, 2, 3].expand((x) {
    if (x == 2) throw "FAIL";
    return [x, x];
  });
  Iterator it = iterable.iterator;
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.isTrue(it.moveNext());
  Expect.equals(1, it.current);
  Expect.throws(it.moveNext, (e) => e == "FAIL");
  // After throwing, iteration is ended.
  Expect.equals(null, it.current);
  Expect.isFalse(it.moveNext());
}
