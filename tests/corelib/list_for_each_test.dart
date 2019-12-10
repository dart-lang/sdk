// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:collection";

class MyList extends ListBase {
  List list;
  MyList(this.list);
  get length => list.length;
  set length(value) {
    list.length = value;
  }

  operator [](index) => list[index];
  operator []=(index, val) {
    list[index] = val;
  }

  toString() => list.toString();
}

void testWithoutModification(List list) {
  var seen = [];
  list.forEach(seen.add);

  Expect.listEquals(list, seen);
}

void testWithModification(List list) {
  if (list.isEmpty) return;
  Expect.throws(() => list.forEach((_) => list.add(0)),
      (e) => e is ConcurrentModificationError);
}

main() {
  List fixedLengthList = new List(10);
  for (int i = 0; i < 10; i++) fixedLengthList[i] = i + 1;

  List growableList = new List();
  growableList.length = 10;
  for (int i = 0; i < 10; i++) growableList[i] = i + 1;

  var growableLists = [
    [],
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    new MyList([1, 2, 3, 4, 5]),
    growableList,
  ];
  var fixedLengthLists = [
    const [],
    fixedLengthList,
    const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    new MyList(const [1, 2]),
  ];

  for (var list in growableLists) {
    print(list);
    testWithoutModification(list);
    testWithModification(list);
  }

  for (var list in fixedLengthLists) {
    testWithoutModification(list);
  }
}
