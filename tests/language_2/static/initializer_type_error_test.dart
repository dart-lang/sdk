// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

int x = "milou";
//      ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
// [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.

bool readXThrows() {
  try {
    var y = x;
    return false;
  } catch (e) {
    x = 5; // Make sure we do not throw exception a second time.
    return true;
  }
}

main() {
  int numExceptions = 0;
  for (int i = 0; i < 8; i++) {
    if (readXThrows()) {
      numExceptions++;
    }
  }
  Expect.equals(1, numExceptions);
}
