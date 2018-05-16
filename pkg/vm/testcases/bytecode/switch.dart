// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int foo1(int x) {
  int y;
  switch (x) {
    case 1:
      y = 11;
      break;
    case 2:
      y = 22;
      break;
    case 3:
      y = 33;
      break;
  }
  return y;
}

int foo2(int x) {
  int y;
  switch (x) {
    case 1:
    case 2:
    case 3:
      y = 11;
      break;
    case 4:
    case 5:
    case 6:
      y = 22;
      break;
    default:
      y = 33;
  }
  return y;
}

int foo3(int x) {
  int y;
  switch (x) {
    case 1:
    case 2:
    case 3:
      y = 11;
      continue L5;
    case 4:
    L5:
    case 5:
    case 6:
      y = 22;
      return 42;
    default:
      y = 33;
  }
  return y;
}

main() {}
