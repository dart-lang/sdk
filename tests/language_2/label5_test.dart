// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var L = 33;
  while (false) {
    // Illegal: L is not a label.
    if (true) break L;
    //              ^
    // [analyzer] COMPILE_TIME_ERROR.LABEL_UNDEFINED
    // [cfe] Can't break to 'L'.
  }
}
