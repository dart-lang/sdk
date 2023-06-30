// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests string usage with const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const String str = "str";
const var1 = str[2];
//           ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE

const var2 = fn();
//           ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
fn() {
  String local = "str";
  return local[0];
}

const var3 = "str"[0];
//           ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE

const var4 = fn2();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
fn2() {
  try {
    var x = str[-1];
  } on RangeError {
    return 2;
  }
}

void main() {
  Expect.equals(var1, 'r');
  Expect.equals(var2, 's');
  Expect.equals(var3, 's');
  Expect.equals(var4, 2);
}
