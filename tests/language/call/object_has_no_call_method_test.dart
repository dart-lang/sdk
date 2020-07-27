// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void test(dynamic d, Object o, Function f) {
  d();
  o();
//^
// [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
// ^
// [cfe] The method 'call' isn't defined for the class 'Object'.
  f();
  d.call;
  o.call;
  //^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'call' isn't defined for the class 'Object'.
  f.call;
  d.call();
  o.call();
  //^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] The method 'call' isn't defined for the class 'Object'.
  f.call();
}

main() {}
