// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Illegal to reference a labeled case statement with break.

main() {
  var x = 1;
  L:
  while (true) {
    switch (x) {
      L:
      case 1: // Shadowing another label is OK.
        break L; // Illegal, can't reference labeled case from break.
        //    ^
        // [analyzer] COMPILE_TIME_ERROR.BREAK_LABEL_ON_SWITCH_MEMBER
        // [cfe] Can't break to 'L'.
    }
  }
}
