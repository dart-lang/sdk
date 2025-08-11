// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void test(dynamic d, Object o, Function f) {
  d();
  o();
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
  // [error column 4]
  // [cfe] The method 'call' isn't defined for the type 'Object'.
  f();
  d.call;
  o.call;
  //^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'call' isn't defined for the type 'Object'.
  f.call;
  d.call();
  o.call();
  //^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] The method 'call' isn't defined for the type 'Object'.
  f.call();
}

main() {}
