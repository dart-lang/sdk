// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

testFor() {
  int current;
  for (int i = 0; i < 100; i++) {
    current = i;
    if (i > 41) break;
  }
  Expect.isTrue(current == 42);
}

testWhile() {
  int i = 0;
  while (i < 100) {
    if (++i > 41) break;
  }
  Expect.isTrue(i == 42);
}

testDoWhile() {
  int i = 0;
  do {
    if (++i > 41) break;
  } while (i < 100);
  Expect.isTrue(i == 42);
}

testLabledBreakOutermost() {
  int i = 0;
  outer:
  {
    middle:
    {
      while (i < 100) {
        if (++i > 41) break outer;
      }
      i++;
    }
    i++;
  }
  Expect.isTrue(i == 42);
}

testLabledBreakMiddle() {
  int i = 0;
  outer:
  {
    middle:
    {
      while (i < 100) {
        if (++i > 41) break middle;
      }
      i++;
    }
    i++;
  }
  Expect.isTrue(i == 43);
}

testLabledBreakInner() {
  int i = 0;
  outer:
  {
    middle:
    {
      while (i < 100) {
        if (++i > 41) break;
      }
      i++;
    }
    i++;
  }
  Expect.isTrue(i == 44);
}

main() {
  testFor();
  testWhile();
  testDoWhile();
  testLabledBreakOutermost();
  testLabledBreakMiddle();
  testLabledBreakInner();
}
