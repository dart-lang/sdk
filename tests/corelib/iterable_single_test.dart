// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  List<int> list1a = <int>[1];
  List<int> list1b = <int>[1, 2, 3];
  List<int> list1c = <int>[];
  List<int> list2a = const <int>[5];
  List<int> list2b = const <int>[4, 5];
  List<int> list2c = const <int>[];
  Set<int> set1 = new Set<int>();
  set1..add(22);
  Set set2 = new Set();
  set2..add(11)..add(12)..add(13);
  Set set3 = new Set();

  Expect.equals(1, list1a.single);
  Expect.throwsStateError(() => list1b.single);
  Expect.throwsStateError(() => list1c.single);

  Expect.equals(5, list2a.single);
  Expect.throwsStateError(() => list2b.single);
  Expect.throwsStateError(() => list2c.single);

  Expect.equals(22, set1.single);
  Expect.throwsStateError(() => set2.single);
  Expect.throwsStateError(() => set3.single);
}
