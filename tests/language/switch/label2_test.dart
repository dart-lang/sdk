// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test switch statement using labels.

import 'package:expect/expect.dart';

void main() {
  doSwitch(0, [0, 2]);
  doSwitch(1, [1]);
  doSwitch(2, [2]);
  doSwitch(3, [3, 1]);
}

void doSwitch(int target, List expect) {
  List list = [];
  switch (target) {
    case 0:
      list.add(0);
      continue case2;
    case1:
    case 1:
      list.add(1);
      break;
    case2:
    case 2:
      list.add(2);
      break;
    case 3:
      list.add(3);
      continue case1;
  }
  Expect.listEquals(expect, list);
}
