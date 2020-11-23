// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void useAddAll() {
  dynamic dynamicList1 = <int>[0, 1, 2];
  dynamic dynamicList2 = <num>[3, 4, 5];
  dynamic dynamicList3 = <int?>[6, 7, 8];
  Iterable<int> iterableIntList = <int>[9, 10, 11];
  List<int> intList = <int>[12, 13, 14];

  var list1 = <int>[
    ...dynamicList1,
    ...dynamicList2,
    ...dynamicList3,
    ...iterableIntList,
    ...intList,
  ];

  expect(new List<int>.generate(15, (int i) => i), list1);

  var list2 = <num>[
    ...dynamicList1,
    ...dynamicList2,
    ...dynamicList3,
    ...iterableIntList,
    ...intList,
  ];

  expect(new List<num>.generate(15, (int i) => i), list2);
}

void useAddAllNullable() {
  dynamic dynamicList1 = <int>[0, 1, 2];
  dynamic dynamicList2 = <num>[3, 4, 5];
  dynamic dynamicList3 = <int?>[6, 7, 8];
  Iterable<int>? iterableIntList = true ? <int>[9, 10, 11] : null;
  List<int>? intList = true ? <int>[12, 13, 14] : null;

  var list1 = <int>[
    ...?dynamicList1,
    ...?dynamicList2,
    ...?dynamicList3,
    ...?iterableIntList,
    ...?intList,
  ];

  expect(new List<int>.generate(15, (int i) => i), list1);

  var list2 = <num>[
    ...?dynamicList1,
    ...?dynamicList2,
    ...?dynamicList3,
    ...?iterableIntList,
    ...?intList,
  ];

  expect(new List<num>.generate(15, (int i) => i), list2);
}

main() {
  useAddAll();
  useAddAllNullable();
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
