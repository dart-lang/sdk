// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests recursive function calls for const functions which have a cycle in the
// dependencies.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const dependsOnB = b;
//                 ^
// [cfe] Constant evaluation error:
const b = fn(4);
//        ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn(int a) {
  if (a == 1) return dependsOnB;
  return dependsOnB * fn(a - 1);
}
