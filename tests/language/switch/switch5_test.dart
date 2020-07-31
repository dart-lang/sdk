// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Break' to case label is illegal.

main() {
  var a = 5;
  var x;
  switch (a) {
    L:
    case 1:
      x = 1;
      break;
    case 6:
      x = 2;
      break L;
      //    ^
      // [analyzer] COMPILE_TIME_ERROR.BREAK_LABEL_ON_SWITCH_MEMBER
      // [cfe] Can't break to 'L'.
    default:
      break;
  }
  return a;
}
