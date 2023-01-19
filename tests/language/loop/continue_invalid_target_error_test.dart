// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  L:
  {
    for (var i in []) {
      continue L;
//    ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONTINUE_LABEL_INVALID
//    ^^^^^^^^
// [cfe] A 'continue' label must be on a loop or a switch member.
    }
  }
  1;
}
