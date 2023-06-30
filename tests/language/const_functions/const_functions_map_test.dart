// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests map usage with const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const var1 = fn({'key': 'val'}, 'key');
//           ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION

const var2 = fn({'key': 2}, 'key');
//           ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION

const var3 = fn({'key': 2}, 'invalid');
//           ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION

const map = {'key1': 2, 'key2': 3, 'key3': 4};
const var4 = fn(map, 'key1');
//           ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
const var5 = fn(map, 'key2');
//           ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
const var6 = fn(map, 'key3');
//           ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION

Object? fn(Map<Object, Object> map, Object key) {
  return map[key];
}

const var7 = fn2();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int? fn2() {
  const y = {'key': 2};
  return y['key'];
}

void main() {
  Expect.equals(var1, 'val');
  Expect.equals(var2, 2);
  Expect.equals(var3, null);
  Expect.equals(var4, 2);
  Expect.equals(var5, 3);
  Expect.equals(var6, 4);
  Expect.equals(var7, 2);
}
