// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

method() {
  return 0;
}

main() {
  // Illegal, can't change a top level method
  method = () {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FUNCTION
// [cfe] Setter not found: 'method'.
    return 1;
  };
}
