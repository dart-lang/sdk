// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests function invocation return types.

import "package:expect/expect.dart";

const var1 = fn();
void fn() {}

const var2 = fn2();
void fn2() {
  return;
}

const var3 = fn3();
int? fn3() => null;

const var4 = fn4();
int? fn4() {
  return null;
}

const var5 = fn5();
int fn5() {
  try {
    return throw 1;
  } on int {
    return 2;
  }
}

void main() {
  Expect.equals((var1 as dynamic), null);
  Expect.equals((var2 as dynamic), null);
  Expect.equals(var3, null);
  Expect.equals(var4, null);
  Expect.equals(var5, 2);
}
