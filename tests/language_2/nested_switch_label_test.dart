// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test nested switch statement using labels.

library nested_switch_label;

import "package:expect/expect.dart";

void main() {
  doSwitch(0, ['0', '2:0', '1', 'default']);
  doSwitch(2, ['2:2', '2:1', '2', '1', 'default']);
}

void doSwitch(int target, List expect) {
  List list = [];
  switch (target) {
    outer0:
    case 0:
      list.add('0');
      continue outer2;
    outer1:
    case 1:
      list.add('1');
      continue outerDefault;
    outer2:
    case 2:
      switch (target) {
        inner0:
        case 0:
          list.add('2:0');
          continue outer1;
        inner2:
        case 2:
          list.add('2:2');
          continue inner1;
        inner1:
        case 1:
          list.add('2:1');
      }
      list.add('2');
      continue outer1;
    outerDefault:
    default:
      list.add('default');
  }
  Expect.listEquals(expect, list);
}
