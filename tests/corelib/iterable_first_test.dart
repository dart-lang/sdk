// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  List<int> list1 = <int>[1, 2, 3];
  List<int> list2 = const <int>[4, 5];
  List<String> list3 = <String>[];
  Set<int> set1 = new Set<int>();
  set1..add(11)..add(12)..add(13);
  Set set2 = new Set();

  Expect.equals(1, list1.first);
  Expect.equals(4, list2.first);
  Expect.throws(() => list3.first, (e) => e is StateError);

  Expect.isTrue(set1.contains(set1.first));

  Expect.throws(() => set2.first, (e) => e is StateError);
}
