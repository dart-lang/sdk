// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests lists with const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const firstVar = firstFn();
//               ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int firstFn() {
  const List<int> x = [1, 2];
  return x.first;
}

const firstCatchVar = firstCatchFn();
//                    ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int firstCatchFn() {
  try {
    const List<int> x = [];
    var v = x.first;
  } on StateError {
    return 0;
  }
  return 1;
}

const isEmptyVar = isEmptyFn();
//                 ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
bool isEmptyFn() {
  const List<int> x = [1, 2];
  return x.isEmpty;
}

const isNotEmptyVar = isNotEmptyFn();
//                    ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
bool isNotEmptyFn() {
  const List<int> x = [1, 2];
  return x.isNotEmpty;
}

const lastVar = lastFn();
//              ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int lastFn() {
  const List<int> x = [1, 2];
  return x.last;
}

const lastCatchVar = lastCatchFn();
//                   ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
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
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int lengthFn() {
  const List<int> x = [1, 2];
  return x.length;
}

const singleVar = singleFn();
//                ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int singleFn() {
  const List<int> x = [1];
  return x.single;
}

const singleCatchVar = singleCatchFn();
//                     ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
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
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int singleCatchFn2() {
  try {
    const List<int> x = [1, 2];
    var v = x.single;
  } on StateError {
    return 0;
  }
  return 1;
}

const getWithIndexVar = getWithIndexFn();
//                      ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int getWithIndexFn() {
  const List<int> x = [1];
  return x[0];
}

const rangeErrorCatchVar = rangeErrorCatchFn();
//                         ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int rangeErrorCatchFn() {
  try {
    const List<int> x = [1];
    var v = x[1];
  } on RangeError {
    return 0;
  }
  return 1;
}

const mutableListVar = mutableList();
//                     ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
List<int> mutableList() {
  List<int> x = [1, 2];
  return x;
}

const mutableListAddVar = mutableListAdd();
//                        ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
List<int> mutableListAdd() {
  List<int> x = [1, 2];
  x.add(3);
  return x;
}

void main() {
  Expect.equals(firstVar, 1);
  Expect.equals(firstCatchVar, 0);
  Expect.equals(isEmptyVar, false);
  Expect.equals(isNotEmptyVar, true);
  Expect.equals(lastVar, 2);
  Expect.equals(lastCatchVar, 0);
  Expect.equals(lengthVar, 2);
  Expect.equals(singleVar, 1);
  Expect.equals(singleCatchVar, 0);
  Expect.equals(singleCatchVar2, 0);
  Expect.equals(getWithIndexVar, 1);
  Expect.equals(rangeErrorCatchVar, 0);
  Expect.equals(mutableListVar, const [1, 2]);
  Expect.equals(mutableListAddVar, const [1, 2, 3]);
}
