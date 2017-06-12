// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int x = "milou";
bool inCheckedMode = false;

bool readXThrows() {
  try {
    var y = x;
    return false;
  } catch (e) {
    inCheckedMode = true;
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
  // In checked mode throw only one exception.
  Expect.equals(inCheckedMode ? 1 : 0, numExceptions);
}
