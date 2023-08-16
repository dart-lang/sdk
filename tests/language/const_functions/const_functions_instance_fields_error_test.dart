// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous instance field usage with const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

class A {
  final int y;

  const A(this.y);
}

const var1 = fn();
//           ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn() => const A(1).x;
//                     ^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
// [cfe] The getter 'x' isn't defined for the class 'A'.

const var2 = fn2();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn2() {
  var x = const A(1);
  return x.x;
  //       ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'x' isn't defined for the class 'A'.
}

const var3 = const A(1).x;
//           ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
//                      ^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
// [cfe] The getter 'x' isn't defined for the class 'A'.
