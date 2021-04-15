// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests lists with const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const firstVar = firstFn();
//               ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [web] Constant evaluation error:
int firstFn() {
  const List<int> x = [1, 2];
  return x.first;
}

const firstCatchVar = firstCatchFn();
//                    ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [web] Constant evaluation error:
int firstCatchFn() {
  try {
    const List<int> x = [];
    var v = x.first;
  } on StateError {
    return 0;
  }
  return 1;
}

const hashCodeVar = hashCodeFn();
//                  ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [web] Constant evaluation error:
int hashCodeFn() {
  const List<int> x = [1, 2];
  return x.hashCode;
}

const isEmptyVar = isEmptyFn();
//                 ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [web] Constant evaluation error:
bool isEmptyFn() {
  const List<int> x = [1, 2];
  return x.isEmpty;
}

const isNotEmptyVar = isNotEmptyFn();
//                    ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [web] Constant evaluation error:
bool isNotEmptyFn() {
  const List<int> x = [1, 2];
  return x.isNotEmpty;
}

const lastVar = lastFn();
//              ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [web] Constant evaluation error:
int lastFn() {
  const List<int> x = [1, 2];
  return x.last;
}

const lastCatchVar = lastCatchFn();
//                   ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [web] Constant evaluation error:
int lastCatchFn() {
  try {
    const List<int> x = [];
    var v = x.last;
  } on StateError {
    return 0;
  }
  return 1;
}

const lengthVar = lengthFn();
//                ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [web] Constant evaluation error:
int lengthFn() {
  const List<int> x = [1, 2];
  return x.length;
}

const singleVar = singleFn();
//                ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [web] Constant evaluation error:
int singleFn() {
  const List<int> x = [1];
  return x.single;
}

const singleCatchVar = singleCatchFn();
//                     ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [web] Constant evaluation error:
int singleCatchFn() {
  try {
    const List<int> x = [];
    var v = x.single;
  } on StateError {
    return 0;
  }
  return 1;
}

const singleCatchVar2 = singleCatchFn2();
//                      ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [web] Constant evaluation error:
int singleCatchFn2() {
  try {
    const List<int> x = [1, 2];
    var v = x.single;
  } on StateError {
    return 0;
  }
  return 1;
}

const typeExample = int;
const typeVar = typeFn();
//              ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [web] Constant evaluation error:
Type typeFn() {
  const List<int> x = [1, 2];
  return x.runtimeType;
}

void main() {
  Expect.equals(firstVar, 1);
  Expect.equals(firstCatchVar, 0);
  Expect.type<int>(hashCodeVar);
  Expect.equals(isEmptyVar, false);
  Expect.equals(isNotEmptyVar, true);
  Expect.equals(lastVar, 2);
  Expect.equals(lastCatchVar, 0);
  Expect.equals(lengthVar, 2);
  Expect.equals(singleVar, 1);
  Expect.equals(singleCatchVar, 0);
  Expect.equals(singleCatchVar2, 0);
  Expect.equals(typeVar, int);
}
