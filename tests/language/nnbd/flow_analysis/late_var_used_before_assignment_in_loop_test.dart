// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that when a late variable is read prior to its first
// assignment, but the read and the assignment occur within the body of a loop,
// that there is no compile-time error, because the assignment may happen in an
// earlier iteration than the read.

// SharedOptions=--enable-experiment=non-nullable
import 'package:expect/expect.dart';

void forLoop() {
  late int x;
  for (int i = 0; i < 2; i++) {
    if (i == 1) {
      Expect.equals(x, 10);
    }
    if (i == 0) {
      x = 10;
    }
  }
}

void forEach() {
  late int x;
  for (bool b in [false, true]) {
    if (b) {
      Expect.equals(x, 10);
    }
    if (!b) {
      x = 10;
    }
  }
}

void whileLoop() {
  late int x;
  int i = 0;
  while (i < 2) {
    if (i == 1) {
      Expect.equals(x, 10);
    }
    if (i == 0) {
      x = 10;
    }
    i++;
  }
}

void doLoop() {
  late int x;
  int i = 0;
  do {
    if (i == 1) {
      Expect.equals(x, 10);
    }
    if (i == 0) {
      x = 10;
    }
    i++;
  } while (i < 2);
}

main() {
  forLoop();
  forEach();
  whileLoop();
  doLoop();
}
