// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test nested switch statement using labels.

library nested_switch_label;

import "package:expect/expect.dart";

void main() {
  Expect.throws(() => doSwitch(0), (list) {
    Expect.listEquals([0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], list);
    return true;
  });
  Expect.throws(() => doSwitch(2), (list) {
    Expect.listEquals([2, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0], list);
    return true;
  });
}

void doSwitch(int target) {
  List list = [];
  switch (target) {
    l0:
    case 0:
      if (list.length > 10) throw list;
      list.add(0);
      continue l1;
    l1:
    case 1:
      if (list.length > 10) throw list;
      list.add(1);
      continue l0;
    default:
      list.add(2);
      continue l1;
  }
}
