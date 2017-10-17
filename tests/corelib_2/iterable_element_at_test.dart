// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  List<int> list1 = <int>[1, 2, 3];
  List<int> list2 = const <int>[4, 5, 6];
  List<String> list3 = <String>[];
  Set<int> set1 = new Set<int>();
  set1..add(11)..add(12)..add(13);
  Set set2 = new Set();

  Expect.equals(1, list1.elementAt(0));
  Expect.equals(2, list1.elementAt(1));
  Expect.equals(3, list1.elementAt(2));
  list1.elementAt("2"); //# static: compile-time error
  Expect.throwsArgumentError(() => list1.elementAt(-1));
  Expect.throwsRangeError(() => list1.elementAt(3));

  Expect.equals(4, list2.elementAt(0));
  Expect.equals(5, list2.elementAt(1));
  Expect.equals(6, list2.elementAt(2));
  list2.elementAt("2"); //# static: compile-time error
  Expect.throwsArgumentError(() => list2.elementAt(-1));
  Expect.throwsRangeError(() => list2.elementAt(3));

  Expect.isTrue(set1.contains(set1.elementAt(0)));
  Expect.isTrue(set1.contains(set1.elementAt(1)));
  Expect.isTrue(set1.contains(set1.elementAt(2)));
  Expect.throwsArgumentError(() => set1.elementAt(-1));
  Expect.throwsRangeError(() => set1.elementAt(3));

  set2.elementAt("2"); //# static: compile-time error
  Expect.throwsArgumentError(() => set2.elementAt(-1));
  Expect.throwsRangeError(() => set2.elementAt(0));
  Expect.throwsRangeError(() => set2.elementAt(1));
}
