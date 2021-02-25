// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

void foldInitialElements() {
  dynamic element0 = 0;
  num element1 = 1;
  int element2 = 2;
  var list = <int>[element0, element1, element2, if (true) 3, 4, 5, 6];

  expect(new List<int>.generate(7, (int i) => i), list);

  var set = <int>{element0, element1, element2, if (true) 3, 4, 5, 6};

  expect(new List<int>.generate(7, (int i) => i), set.toList());
}

void foldInitialSpread1() {
  dynamic initial = [0, 1, 2];
  var list = <int>[...initial, if (true) 3, 4, 5, 6];

  expect(new List<int>.generate(7, (int i) => i), list);

  var set = <int>{...initial, if (true) 3, 4, 5, 6};

  expect(new List<int>.generate(7, (int i) => i), set.toList());
}

void foldInitialSpread2() {
  Iterable<num> initial = [0, 1, 2];
  var list = <int>[...initial, if (true) 3, 4, 5, 6];

  expect(new List<int>.generate(7, (int i) => i), list);

  var set = <int>{...initial, if (true) 3, 4, 5, 6};

  expect(new List<int>.generate(7, (int i) => i), set.toList());
}

void foldInitialSpread3() {
  List<num> initial = [0, 1, 2];
  var list = <int>[...initial, if (true) 3, 4, 5, 6];

  expect(new List<int>.generate(7, (int i) => i), list);

  var set = <int>{...initial, if (true) 3, 4, 5, 6};

  expect(new List<int>.generate(7, (int i) => i), set.toList());
}

void foldInitialSpread4() {
  Iterable<int> initial = [0, 1, 2];
  var list = <int>[...initial, if (true) 3, 4, 5, 6];

  expect(new List<int>.generate(7, (int i) => i), list);

  var set = <int>{...initial, if (true) 3, 4, 5, 6};

  expect(new List<int>.generate(7, (int i) => i), set.toList());
}

void foldInitialSpread5() {
  List<int> initial = [0, 1, 2];
  var list = <int>[...initial, if (true) 3, 4, 5, 6];

  expect(new List<int>.generate(7, (int i) => i), list);

  var set = <int>{...initial, if (true) 3, 4, 5, 6};

  expect(new List<int>.generate(7, (int i) => i), set.toList());
}

void foldInitialSpread6() {
  List<int> initial = [0, 1, 2];
  var list = <int>[...?initial, if (true) 3, 4, 5, 6];

  expect(new List<int>.generate(7, (int i) => i), list);

  var set = <int>{...?initial, if (true) 3, 4, 5, 6};

  expect(new List<int>.generate(7, (int i) => i), set.toList());
}

main() {
  foldInitialElements();
  foldInitialSpread1();
  foldInitialSpread2();
  foldInitialSpread3();
  foldInitialSpread4();
  foldInitialSpread5();
  foldInitialSpread6();
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
