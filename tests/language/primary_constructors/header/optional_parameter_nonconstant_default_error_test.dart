// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that declaring constructors with optional parameters cannot have
// non-constant default values in a header declaring constructor.

int f() => 0;

class C([int x = f()]);
//               ^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Method invocation is not a constant expression.

enum E([int x = f()]) {
  //            ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
  // [cfe] Method invocation is not a constant expression.
  e;
}
