// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous list usage with const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const firstException = firstExceptionFn();
//                     ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Constant evaluation error:
int firstExceptionFn() {
  const List<int> x = [];
  return x.first;
}

const lastException = lastExceptionFn();
//                    ^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Constant evaluation error:
int lastExceptionFn() {
  const List<int> x = [];
  return x.last;
}

const singleException = singleExceptionFn();
//                      ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Constant evaluation error:
int singleExceptionFn() {
  const List<int> x = [];
  return x.single;
}

const singleExceptionMulti = singleExceptionMultiFn();
//                           ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Constant evaluation error:
int singleExceptionMultiFn() {
  const List<int> x = [1, 2];
  return x.single;
}

const invalidProperty = invalidPropertyFn();
//                      ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
int invalidPropertyFn() {
  const List<int> x = [1, 2];
  return x.invalidProperty;
  //       ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'invalidProperty' isn't defined for the class 'List<int>'.
}
