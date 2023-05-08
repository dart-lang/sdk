// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for https://github.com/dart-lang/sdk/issues/52202.

typedef A = int?;

void f(x) {
  switch (x) {
    case A(foo: 0):
//       ^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
//            ^
// [cfe] The getter 'foo' isn't defined for the class 'int?'.
      break;
  }
}
