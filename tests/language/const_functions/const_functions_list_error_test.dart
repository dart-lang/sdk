// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous list usage with const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const firstException = firstExceptionFn();
//                     ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Constant evaluation error:
int firstExceptionFn() {
  const List<int> x = [];
  return x.first;
}

const lastException = lastExceptionFn();
//                    ^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Constant evaluation error:
int lastExceptionFn() {
  const List<int> x = [];
  return x.last;
}

const singleException = singleExceptionFn();
//                      ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Constant evaluation error:
int singleExceptionFn() {
  const List<int> x = [];
  return x.single;
}

const singleExceptionMulti = singleExceptionMultiFn();
//                           ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Constant evaluation error:
int singleExceptionMultiFn() {
  const List<int> x = [1, 2];
  return x.single;
}

const invalidProperty = invalidPropertyFn();
//                      ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int invalidPropertyFn() {
  const List<int> x = [1, 2];
  return x.invalidProperty;
  //       ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'invalidProperty' isn't defined for the class 'List<int>'.
}

const getWithIndexException = getWithIndexExceptionFn();
//                            ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Constant evaluation error:
int getWithIndexExceptionFn() {
  const List<int> x = [1];
  return x[1];
}

const getWithIndexException2 = getWithIndexExceptionFn2();
//                             ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Constant evaluation error:
int getWithIndexExceptionFn2() {
  const List<int> x = [1];
  return x[-1];
}

const getWithIndexException3 = getWithIndexExceptionFn3();
//                             ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int getWithIndexExceptionFn3() {
  const List<int> x = [1];
  return x[0.1];
  //       ^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'double' can't be assigned to a variable of type 'int'.
}

const constListAddException = constListAddExceptionFn();
//                            ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Constant evaluation error:
List<int> constListAddExceptionFn() {
  const List<int> x = [1, 2];
  x.add(3);
  return x;
}
