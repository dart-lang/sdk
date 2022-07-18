// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

void useAddAll() {
  dynamic dynamicSet1 = <int>{0, 1, 2};
  dynamic dynamicSet2 = <num>{3, 4, 5};
  Iterable<int> iterableIntSet = <int>{6, 7, 8};
  Iterable<num> iterableNumSet1 = <int>{9, 10, 11};
  Iterable<num> iterableNumSet2 = <num>{12, 13, 14};
  Set<int> intSet = <int>{15, 16, 17};
  Set<num> numSet1 = <int>{18, 19, 20};
  Set<num> numSet2 = <num>{21, 22, 23};

  var set1 = <int>{
    ...dynamicSet1,
    ...dynamicSet2,
    ...iterableIntSet,
    ...iterableNumSet1,
    ...iterableNumSet2,
    ...intSet,
    ...numSet1,
    ...numSet2
  };

  expect(new List<int>.generate(24, (int i) => i).toSet(), set1);

  var set2 = <num>{
    ...dynamicSet1,
    ...dynamicSet2,
    ...iterableIntSet,
    ...iterableNumSet1,
    ...iterableNumSet2,
    ...intSet,
    ...numSet1,
    ...numSet2
  };

  expect(new List<num>.generate(24, (int i) => i).toSet(), set2);

  var set3 = <int>{
    ...?dynamicSet1,
    ...?dynamicSet2,
    ...?iterableIntSet,
    ...?iterableNumSet1,
    ...?iterableNumSet2,
    ...?intSet,
    ...?numSet1,
    ...?numSet2
  };

  expect(new List<int>.generate(24, (int i) => i).toSet(), set3);

  var set4 = <num>{
    ...?dynamicSet1,
    ...?dynamicSet2,
    ...?iterableIntSet,
    ...?iterableNumSet1,
    ...?iterableNumSet2,
    ...?intSet,
    ...?numSet1,
    ...?numSet2
  };

  expect(new List<num>.generate(24, (int i) => i).toSet(), set4);

  Set<int> set5 = {
    ...dynamicSet1,
    ...dynamicSet2,
    ...iterableIntSet,
    ...iterableNumSet1,
    ...iterableNumSet2,
    ...intSet,
    ...numSet1,
    ...numSet2
  };

  expect(new List<int>.generate(24, (int i) => i).toSet(), set5);

  var set6 = {
    ...dynamicSet1,
    ...dynamicSet2,
    ...iterableIntSet,
    ...iterableNumSet1,
    ...iterableNumSet2,
    ...intSet,
    ...numSet1,
    ...numSet2
  };

  expect(new List<dynamic>.generate(24, (int i) => i).toSet(), set6);

  Set<int> set7 = {
    ...?dynamicSet1,
    ...?dynamicSet2,
    ...?iterableIntSet,
    ...?iterableNumSet1,
    ...?iterableNumSet2,
    ...?intSet,
    ...?numSet1,
    ...?numSet2
  };

  expect(new List<int>.generate(24, (int i) => i).toSet(), set7);

  var set8 = {
    ...?dynamicSet1,
    ...?dynamicSet2,
    ...?iterableIntSet,
    ...?iterableNumSet1,
    ...?iterableNumSet2,
    ...?intSet,
    ...?numSet1,
    ...?numSet2
  };

  expect(new List<dynamic>.generate(24, (int i) => i).toSet(), set8);

  {
    Set<int> intSet1 = {0, 1, 2};
    Set<int> intSet2 = {3, 4, 5};
    var set = {...intSet1, ...intSet2};
    expect(new List<int>.generate(6, (int i) => i).toSet(), set);
  }
}

main() {
  useAddAll();
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
  if (set1.runtimeType.toString() != set2.runtimeType.toString()) {
    throw "Runtime time difference: "
        "${set1.runtimeType.toString()} vs ${set2.runtimeType.toString()}";
  }
}
