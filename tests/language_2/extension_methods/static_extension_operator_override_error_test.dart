// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for https://github.com/dart-lang/sdk/issues/43114.

class A {}

extension E on A {
  String operator +(int other) => '';
}

f(A a, int b) {
  int i = E(a) + b;
  //      ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //           ^
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
}

main() {
  f(A(), 0);
}
