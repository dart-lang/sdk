// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void useAddAll() {
  dynamic dynamicSet1 = <int>{0, 1, 2};
  dynamic dynamicSet2 = <num>{3, 4, 5};
  dynamic dynamicSet3 = <int?>{6, 7, 8};
  Iterable<int> iterableIntSet = <int>{9, 10, 11};
  Set<int> intSet = <int>{12, 13, 14};

  var set1 = <int>{
    ...dynamicSet1,
    ...dynamicSet2,
    ...dynamicSet3,
    ...iterableIntSet,
    ...intSet,
  };

  expect(new List<int>.generate(15, (int i) => i).toSet(), set1);

  var set2 = <num>{
    ...dynamicSet1,
    ...dynamicSet2,
    ...dynamicSet3,
    ...iterableIntSet,
    ...intSet,
  };

  expect(new List<num>.generate(15, (int i) => i).toSet(), set2);
}

void useAddAllNullable() {
  dynamic dynamicSet1 = <int>{0, 1, 2};
  dynamic dynamicSet2 = <num>{3, 4, 5};
  dynamic dynamicSet3 = <int?>{6, 7, 8};
  Iterable<int>? iterableIntSet = true ? <int>{9, 10, 11} : null;
  Set<int>? intSet = true ? <int>{12, 13, 14} : null;

  var set1 = <int>{
    ...?dynamicSet1,
    ...?dynamicSet2,
    ...?dynamicSet3,
    ...?iterableIntSet,
    ...?intSet,
  };

  expect(new List<int>.generate(15, (int i) => i).toSet(), set1);

  var set2 = <num>{
    ...?dynamicSet1,
    ...?dynamicSet2,
    ...?dynamicSet3,
    ...?iterableIntSet,
    ...?intSet,
  };

  expect(new List<num>.generate(15, (int i) => i).toSet(), set2);
}

main() {
  useAddAll();
  useAddAllNullable();
}

void expect(Set set1, Set set2) {
  if (set1.length != set2.length) {
    throw 'Unexpected length. Expected ${set1.length}, actual ${set2.length}.';
  }
  for (dynamic element in set1) {
    if (!set2.contains(element)) {
      throw 'Element $element not found. Expected $set1, actual $set2.';
    }
  }
}
