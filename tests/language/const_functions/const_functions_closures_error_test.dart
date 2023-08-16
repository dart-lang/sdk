// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous closure situations with const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

var varVariable = 1;
const var1 = fn();
//           ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Constant evaluation error:
int fn() {
  return varVariable;
}

final finalVariable = 1;
const var2 = fn2();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Constant evaluation error:
int fn2() {
  return finalVariable;
}

const var3 = fn3();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn3() {
  int innerFn() {
    return x;
    //     ^
    // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
  }

  const x = 0;
  //    ^
  // [cfe] Can't declare 'x' because it was already used in this scope.
  return innerFn();
}

const var4 = fn4();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn4() {
  var a = () {
    return x;
    //     ^
    // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
  };
  var x = 1;
  //  ^
  // [cfe] Can't declare 'x' because it was already used in this scope.
  return a();
}

const var5 = fn5(1);
//           ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
fn5(a) {
  var a = () => a;
  //  ^
  // [cfe] Can't declare 'a' because it was already used in this scope.
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
  return a();
}

const x = 0;
void fn6() {
  var x = 1;
  int a() => x;
  const z = a();
  //        ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
  // [cfe] Constant evaluation error:
}
