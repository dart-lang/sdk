// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that when a late variable is read prior to its first
// assignment, and the read occurs within the body of an unlabelled case block,
// and the assignment occurs elsewhere in the switch, that there is a
// compile-time error, because the variable is unassigned on all possible
// control flow paths to the read.

// SharedOptions=--enable-experiment=non-nullable
import 'package:expect/expect.dart';

void switchBad(int value) {
  late int x;
  switch (value) {
    case 0:
      Expect.equals(x, 10);
      //            ^
      // [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
      // [cfe] Late variable 'x' without initializer is definitely unassigned.
      break;
    case 1:
      x = 10;
      break;
  }
}

main() {
  switchBad(1);
}
