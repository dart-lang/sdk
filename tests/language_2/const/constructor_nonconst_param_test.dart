// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  const A(int a);
}

class B {
  final a;
  const B(dynamic v) //
      : a = A(v)
      //    ^^^^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
      // [cfe] Constant evaluation error:
      //    ^
      // [cfe] Constant expression expected.
  ;
}

void main() {
  const B("");
//^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_THROWS_EXCEPTION
}
