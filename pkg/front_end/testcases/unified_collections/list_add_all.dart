// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

void useAddAll() {
  dynamic dynamicList1 = <int>[0, 1, 2];
  dynamic dynamicList2 = <num>[3, 4, 5];
  Iterable<int> iterableIntList = <int>[6, 7, 8];
  Iterable<num> iterableNumList1 = <int>[9, 10, 11];
  Iterable<num> iterableNumList2 = <num>[12, 13, 14];
  List<int> intList = <int>[15, 16, 17];
  List<num> numList1 = <int>[18, 19, 20];
  List<num> numList2 = <num>[21, 22, 23];

  var list1 = <int>[
    ...dynamicList1,
    ...dynamicList2,
    ...iterableIntList,
    ...iterableNumList1,
    ...iterableNumList2,
    ...intList,
    ...numList1,
    ...numList2
  ];

  expect(new List<int>.generate(24, (int i) => i), list1);

  var list2 = <num>[
    ...dynamicList1,
    ...dynamicList2,
    ...iterableIntList,
    ...iterableNumList1,
    ...iterableNumList2,
    ...intList,
    ...numList1,
    ...numList2
  ];

  expect(new List<num>.generate(24, (int i) => i), list2);

  var list3 = <int>[
    ...?dynamicList1,
    ...?dynamicList2,
    ...?iterableIntList,
    ...?iterableNumList1,
    ...?iterableNumList2,
    ...?intList,
    ...?numList1,
    ...?numList2
  ];

  expect(new List<int>.generate(24, (int i) => i), list3);

  var list4 = <num>[
    ...?dynamicList1,
    ...?dynamicList2,
    ...?iterableIntList,
    ...?iterableNumList1,
    ...?iterableNumList2,
    ...?intList,
    ...?numList1,
    ...?numList2
  ];

  expect(new List<num>.generate(24, (int i) => i), list4);
}

main() {
  useAddAll();
}

void expect(List list1, List list2) {
  if (list1.length != list2.length) {
    throw 'Unexpected length. Expected ${list1.length}, actual ${list2.length}.';
  }
  for (int i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) {
      throw 'Unexpected element at index $i. '
          'Expected ${list1[i]}, actual ${list2[i]}.';
    }
  }
}
