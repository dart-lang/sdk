// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

simpleForLoop(count) {
  for (int i = 0; i < count; i = i + 1) {
    print(i);
  }
}

simpleForLoopWithBreak(count) {
  /*0@break*/ for (int i = 0; i < count; i = i + 1) {
    if (i % 2 == 0) /*target=0*/ break;
    print(i);
  }
}

main() {
  simpleForLoop(10);
  simpleForLoopWithBreak(10);
}
