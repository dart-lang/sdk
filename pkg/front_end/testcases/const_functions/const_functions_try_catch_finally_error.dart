// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous try-catch and try-finally with const functions.

import "package:expect/expect.dart";

const var1 = finallyThrow(0);
const var2 = finallyThrow(1);
int finallyThrow(int x) {
  try {
    if (x == 1) {
      throw x;
    } else {
      return 0;
    }
  } finally {
    throw 2;
  }
}

const var3 = unhandledThrow(0);
const var4 = unhandledThrow("string");
int unhandledThrow(dynamic x) {
  try {
    throw x;
  } on String catch (e) {
    throw e;
  }
}

const var5 = unhandledThrow2();
int unhandledThrow2() {
  int count = 0;
  for (int i = 0; i < 1; throw 'a') {
    count += i;
  }
  return 0;
}

main() {}
