// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

nestedForLoopWithBreakAndContinue(count) {
  /*0@continue*/ for (int i = 0; i < count; i = i + 1) {
    /*1@break*/ for (int j = 0; j < count; j = j + 1) {
      if (i % 2 == 0) /*target=1*/ break;
    }
    if (i % 2 == 0) /*target=0*/ continue;
  }
}

nestedForLoopWithLabelledBreak(count) {
  outer:
  /*0@break*/
  for (int i = 0; i < count; i = i + 1) {
    for (int j = 0; j < count; j = j + 1) {
      if (i % 2 == 0) /*target=0*/ break outer;
    }
  }
}

main() {
  nestedForLoopWithBreakAndContinue(10);
  nestedForLoopWithLabelledBreak(10);
}
