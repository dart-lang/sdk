// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class ConstListTest {
  static testConstructors() {
    List fixedList = List.filled(4, -1, growable: false);
    List fixedList2 = List.filled(4, -1, growable: false);
    List growableList = List.filled(0, -1, growable: true);
    List growableList2 = List.filled(0, -1, growable: true);
    for (int i = 0; i < 4; i++) {
      fixedList[i] = i;
      fixedList2[i] = i;
      growableList.add(i);
      growableList2.add(i);
    }
    Expect.equals(growableList, growableList);
    Expect.notEquals(growableList, growableList2);
    Expect.equals(fixedList, fixedList);
    Expect.notEquals(fixedList, fixedList2);
    Expect.notEquals(fixedList, growableList);
    growableList.add(4);
    Expect.notEquals(fixedList, growableList);
    Expect.equals(4, growableList.removeLast());
    Expect.notEquals(fixedList, growableList);
    fixedList[3] = 0;
    Expect.notEquals(fixedList, growableList);
  }

  static testLiterals() {
    dynamic a = [1, 2, 3.1];
    dynamic b = [1, 2, 3.1];
    Expect.notEquals(a, b);
    a = const [1, 2, 3.1];
    b = const [1, 2, 3.1];
    Expect.identical(a, b);
    a = const <num>[1, 2, 3.1];
    b = const [1, 2, 3.1];
    Expect.identical(a, b);
    a = const <dynamic>[1, 2, 3.1];
    b = const [1, 2, 3.1];
    Expect.notEquals(a, b);
  }
}

main() {
  ConstListTest.testConstructors();
  ConstListTest.testLiterals();
}
