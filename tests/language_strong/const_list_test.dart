// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class ConstListTest {

  static testConstructors() {
    List fixedList = new List(4);
    List fixedList2 = new List(4);
    List growableList = new List();
    List growableList2 = new List();
    for (int i = 0; i < 4; i++) {
      fixedList[i] = i;
      fixedList2[i] = i;
      growableList.add(i);
      growableList2.add(i);
    }
    Expect.equals(true, growableList == growableList);
    Expect.equals(false, growableList == growableList2);
    Expect.equals(true, fixedList == fixedList);
    Expect.equals(false, fixedList == fixedList2);
    Expect.equals(false, fixedList == growableList);
    growableList.add(4);
    Expect.equals(false, fixedList == growableList);
    Expect.equals(4, growableList.removeLast());
    Expect.equals(false, fixedList == growableList);
    fixedList[3] = 0;
    Expect.equals(false, fixedList == growableList);
  }

  static testLiterals() {
    var a = [1, 2, 3.1];
    var b = [1, 2, 3.1];
    Expect.equals(false, a == b);
    a = const [1, 2, 3.1];
    b = const [1, 2, 3.1];
    Expect.equals(true, a == b);
    a = const <num>[1, 2, 3.1];
    b = const [1, 2, 3.1];
    Expect.equals(false, a == b);
    a = const <dynamic>[1, 2, 3.1];
    b = const [1, 2, 3.1];
    Expect.equals(true, a == b);
  }
}

main() {
  ConstListTest.testConstructors();
  ConstListTest.testLiterals();
}
