// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Discover unresolved case labels.

main() {
  var a = 5;
  var x;
  switch (a) {
    case 1:
//  ^
// [cfe] Switch case may fall through to the next case.
      x = 1;
      continue L;
//    ^
// [cfe] Can't find label 'L'.
//             ^
// [analyzer] COMPILE_TIME_ERROR.LABEL_UNDEFINED
    case 6:
      x = 2;
      break;
    case 8:
      break;
  }
  return a;
}
