// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests closures with const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const var1 = foo();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int foo() {
  var f = () {
    int count = 0;
    int baz() {
      ++count;
      return count;
    }

    return baz;
  };
  var c1 = f();
  var c2 = f();

  var c1_val1 = c1();
  assert(c1_val1 == 1);
  var c1_val2 = c1();
  assert(c1_val2 == 2);
  var c1_val3 = c1();
  assert(c1_val3 == 3);

  var c2_val1 = c2();
  assert(c1_val1 == 1);
  var c2_val2 = c2();
  assert(c1_val2 == 2);
  var c2_val3 = c2();
  assert(c1_val3 == 3);

  return 0;
}

const var2 = fn();
//           ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn() {
  return (() => 0)();
}

const y = 1;
const var3 = fn3();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn3() {
  int y = 2;
  return y;
}

const var4 = fn4();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn4() {
  var x = 0;
  int innerFn() {
    return x;
  }

  return innerFn();
}

const var5 = fn5(3);
//           ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn5(int a) {
  int recurse(int b) {
    if (b == 1) return 1;
    int result = recurse(b - 1);
    return b * result;
  }

  return recurse(a);
}

const var6 = fn6(4);
//           ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn6(int a) {
  int recurse() {
    a--;
    if (a == 1) return 1;
    return a * recurse();
  }

  return recurse();
}

void main() {
  Expect.equals(var1, 0);
  Expect.equals(var2, 0);
  Expect.equals(var3, 2);
  Expect.equals(var4, 0);
  Expect.equals(var5, 6);
  Expect.equals(var6, 6);
}
