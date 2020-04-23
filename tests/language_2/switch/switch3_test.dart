// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Check that 'continue' to switch statement is illegal.

main() {
  var a = 5;
  var x;
  switch (a) {
    case 1: x = 1; break;
    case 6: x = 2; continue;
//  ^
// [cfe] Switch case may fall through to the next case.
//                 ^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.CONTINUE_WITHOUT_LABEL_IN_CASE
// [cfe] A continue statement in a switch statement must have a label as a target.
    case 8:  break;
  }
  return a;
}
