// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests for the contains methods on lists.

test(list, notInList) {
  testList(list) {
    for (int i = 0; i < list.length; i++) {
      var elem = list[i];
      Expect.isTrue(list.contains(list[i]), "$list.contains($elem)");
    }
    Expect.isFalse(list.contains(notInList), "!$list.contains($notInList)");
  }

  List fixedList = new List(list.length);
  List growList = new List();
  for (int i = 0; i < list.length; i++) {
    fixedList[i] = list[i];
    growList.add(list[i]);
  }
  testList(list);
  testList(fixedList);
  testList(growList);
}

class C {
  const C();
}

class Niet {
  bool operator ==(other) => false;
}

main() {
  test(const <String>["a", "b", "c", null], "d");
  test(const <int>[1, 2, 3, null], 0);
  test(const <bool>[true, false], null);
  test(const <C>[const C(), const C(), null], new C());
  test(<C>[new C(), new C(), new C(), null], new C());
  test(const <double>[0.0, 1.0, 5e-324, 1e+308, double.infinity], 2.0);
  Expect.isTrue(const <double>[-0.0].contains(0.0));
  Expect.isFalse(const <double>[double.nan].contains(double.nan));
  var niet = new Niet();
  Expect.isFalse([niet].contains(niet));
}
