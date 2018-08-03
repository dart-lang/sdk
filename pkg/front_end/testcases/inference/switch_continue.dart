// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

// Note: there are no expectations to fulfill here; we just want to make sure
// that inference completes without crashing.

void test(int x, void f()) {
  switch (x) {
    case 0:
      f();
      continue L;
    L:
    case 1:
      f();
      break;
  }
}

main() {}
