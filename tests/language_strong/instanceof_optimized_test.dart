// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing optimized 'is' tests.
// VMOptions=--optimization-counter-threshold=5 --no-use-osr

import "package:expect/expect.dart";

bool isInt(x) => x is int;

int isIntRes(x) {
  if (x is int) {
    return 1;
  } else {
    return 0;
  }
}

int isNotIntRes(x) {
  if (x is! int) {
    return 1;
  } else {
    return 0;
  }
}

int isIfThenElseIntRes(x) {
  return x is int ? 1 : 0;
}

bool isString(x) => x is String;

int isStringRes(x) {
  if (x is String) {
    return 1;
  } else {
    return 0;
  }
}

int isNotStringRes(x) {
  if (x is! String) {
    return 1;
  } else {
    return 0;
  }
}

main() {
  for (int i = 0; i < 20; i++) {
    Expect.isFalse(isInt(3.2));
    Expect.isTrue(isInt(3));
    Expect.isTrue(isInt(17179869184)); // Mint on ia32.
    Expect.isFalse(isString(2.0));
    Expect.isTrue(isString("Morgan"));
  }
  // No deoptimization of isInt possible since all types are known by the compiler

  Expect.isFalse(isString(true));
  for (int i = 0; i < 20; i++) {
    Expect.isFalse(isInt(3.2));
    Expect.isTrue(isInt(3));
    Expect.isTrue(isInt(17179869184)); // Mint on ia32.
    Expect.isFalse(isInt("hu"));
    Expect.isFalse(isString(2.0));
    Expect.isTrue(isString("Morgan"));
    Expect.isFalse(isString(true));
  }

  for (int i = 0; i < 20; i++) {
    Expect.equals(0, isIntRes(3.2));
    Expect.equals(1, isIntRes(3));
    Expect.equals(0, isIntRes("hi"));
    Expect.equals(1, isNotIntRes(3.2));
    Expect.equals(0, isNotIntRes(3));
    Expect.equals(1, isNotIntRes("hi"));
    Expect.equals(0, isIfThenElseIntRes(3.2));
    Expect.equals(1, isIfThenElseIntRes(3));
    Expect.equals(0, isIfThenElseIntRes("hi"));
  }

  for (int i = 0; i < 20; i++) {
    Expect.equals(0, isStringRes(3.2));
    Expect.equals(1, isStringRes("Lotus"));
    Expect.equals(1, isNotStringRes(3.2));
    Expect.equals(0, isNotStringRes("Lotus"));
  }

  // Deoptimize 'isStringRes', 'isNotIntRes'.
  Expect.equals(0, isStringRes(null));
  Expect.equals(1, isNotIntRes(null));
  for (int i = 0; i < 20; i++) {
    Expect.equals(0, isStringRes(3.2));
    Expect.equals(1, isStringRes("Lotus"));
    Expect.equals(0, isStringRes(null));

    Expect.equals(1, isNotStringRes(3.2));
    Expect.equals(0, isNotStringRes("Lotus"));
    Expect.equals(1, isNotStringRes(null));
  }
}
