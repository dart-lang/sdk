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
  Expect.throwsStateError(() => list1.singleWhere((x) => x.isOdd));

  Expect.equals(6, list2.singleWhere((x) => x == 6));
  Expect.equals(5, list2.singleWhere((x) => x.isOdd));
  Expect.throwsStateError(() => list2.singleWhere((x) => x.isEven));

  Expect.throwsStateError(() => list3.singleWhere((x) => x == 0));

  Expect.equals(12, set1.singleWhere((x) => x.isEven));
  Expect.equals(11, set1.singleWhere((x) => x == 11));
  Expect.throwsStateError(() => set1.singleWhere((x) => x.isOdd));

  Expect.throwsStateError(() => set2.singleWhere((x) => true));
}
