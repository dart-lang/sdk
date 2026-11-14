// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// RunKernelTransformation:UCE
// ignore_for_file: dead_code

int unreachableSwitchCase() {
  const zero = 0;
  switch (zero) {
    case 0:
      return 1;
      continue L;
    L:
    case 1:
      return 999;
    default:
      return 2;
  }
}

int unreachableSwitchCase2() {
  const zero = 0;
  switch (zero) {
    L:
    case 1:
      return 999;
    default:
      return 2;
      continue L;
  }
}

int reachableSwitchCaseViaBackwardContinue(bool c) {
  const zero = 0;
  switch (zero) {
    L:
    case 1:
      print(1);
      break;
    default:
      if (c) continue L;
      print(2);
  }
  return 3;
}

void main() {}
