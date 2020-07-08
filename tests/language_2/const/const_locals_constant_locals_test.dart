// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that constant local variables have constant initializers.

import "package:expect/expect.dart";

void main() {
  const c1;
  //    ^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_NOT_INITIALIZED
  // [cfe] The const variable 'c1' must be initialized.
  const c2 = 0;
  const c3 = field;
  //         ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] Constant evaluation error:
  //         ^
  // [cfe] Not a constant expression.
  const c4 = finalField;
  //         ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] Constant evaluation error:
  //         ^
  // [cfe] Not a constant expression.
  const c5 = constField;
  const c6 = method();
  //         ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] Method invocation is not a constant expression.
  const c7 = new Class();
  //         ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] New expression is not a constant expression.
  const c8 = const Class();
}

var field = 0;

final finalField = 0;

const constField = 0;

method() => 0;

class Class {
  const Class();
}
