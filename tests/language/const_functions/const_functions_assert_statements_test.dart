// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests assert statements with const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const var1 = fn();
//           ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn() {
  int x = 0;
  assert(x == 0, "fail");
  return x;
}

const var2 = fn2();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn2() {
  int x = 0;
  assert(() {
    var y = x + 1;
    return y == 1;
  }());
  return x;
}

void main() {
  Expect.equals(var1, 0);
  Expect.equals(var2, 0);
}
