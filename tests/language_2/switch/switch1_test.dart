// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Check that default clause must be last case.

main() {
  var a = 5;
  var x;
  S: switch (a) {
    case 1: x = 1; break;
    case 6: x = 2; break S;
    default:
//  ^
// [cfe] Switch case may fall through to the next case.
    case 8:  break;
//  ^^^^
// [analyzer] SYNTACTIC_ERROR.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE
// [cfe] The default case should be the last case in a switch statement.
  }
  return a;
}
