// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  List<int> list1 = <int>[1, 2, 3];
  List<int> list2 = const <int>[4, 5, 6];
  List<String> list3 = <String>[];
  Set<int> set1 = new Set<int>();
  set1..add(11)..add(12)..add(13);
  Set set2 = new Set();

  Expect.equals(2, list1.singleWhere((x) => x.isEven));
  Expect.equals(3, list1.singleWhere((x) => x == 3));
  Expect.throws(
      () => list1.singleWhere((x) => x.isOdd), (e) => e is StateError);

  Expect.equals(6, list2.singleWhere((x) => x == 6));
  Expect.equals(5, list2.singleWhere((x) => x.isOdd));
  Expect.throws(
      () => list2.singleWhere((x) => x.isEven), (e) => e is StateError);

  Expect.throws(() => list3.singleWhere((x) => x == 0), (e) => e is StateError);

  Expect.equals(12, set1.singleWhere((x) => x.isEven));
  Expect.equals(11, set1.singleWhere((x) => x == 11));
  Expect.throws(() => set1.singleWhere((x) => x.isOdd));

  Expect.throws(() => set2.singleWhere((x) => true), (e) => e is StateError);
}
