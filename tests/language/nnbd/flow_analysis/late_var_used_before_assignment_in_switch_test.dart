// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that when a late variable is read prior to its first
// assignment, but the read occurs within the body of a labelled case block, and
// the assignment occurs somewhere in the switch, that there is no compile-time
// error, because the assignment may happen prior to a branch to the label.

// SharedOptions=--enable-experiment=non-nullable
import 'package:expect/expect.dart';

void switchOk(int one) {
  late int x;
  switch (one) {
    L:
    case 0:
      Expect.equals(x, 10);
      break;
    case 1:
      x = 10;
      continue L;
  }
}

main() {
  switchOk(1);
}
