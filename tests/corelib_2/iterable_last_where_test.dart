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

  Expect.equals(2, list1.lastWhere((x) => x.isEven));
  Expect.equals(3, list1.lastWhere((x) => x.isOdd));
  Expect.throwsStateError(() => list1.lastWhere((x) => x > 3));
  Expect.equals(null, list1.lastWhere((x) => x > 3, orElse: () => null));
  Expect.equals(499, list1.lastWhere((x) => x > 3, orElse: () => 499));

  Expect.equals(6, list2.lastWhere((x) => x.isEven));
  Expect.equals(5, list2.lastWhere((x) => x.isOdd));
  Expect.throwsStateError(() => list2.lastWhere((x) => x == 0));
  Expect.equals(null, list2.lastWhere((x) => false, orElse: () => null));
  Expect.equals(499, list2.lastWhere((x) => false, orElse: () => 499));

  Expect.throwsStateError(() => list3.lastWhere((x) => x == 0));
  Expect.throwsStateError(() => list3.lastWhere((x) => true));
  Expect.equals(null, list3.lastWhere((x) => true, orElse: () => null));
  Expect.equals("str", list3.lastWhere((x) => false, orElse: () => "str"));

  Expect.equals(12, set1.lastWhere((x) => x.isEven));
  var odd = set1.lastWhere((x) => x.isOdd);
  Expect.isTrue(odd == 11 || odd == 13);
  Expect.throwsStateError(() => set1.lastWhere((x) => false));
  Expect.equals(null, set1.lastWhere((x) => false, orElse: () => null));
  Expect.equals(499, set1.lastWhere((x) => false, orElse: () => 499));

  Expect.throwsStateError(() => set2.lastWhere((x) => false));
  Expect.throwsStateError(() => set2.lastWhere((x) => true));
  Expect.equals(null, set2.lastWhere((x) => true, orElse: () => null));
  Expect.equals(499, set2.lastWhere((x) => false, orElse: () => 499));
}
