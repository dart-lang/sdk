// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Disallow re-assignment of a final static variable.

class A {
  static const x = 1;
}

class B {
  const B() : n = 5;
  final n;
  static const a;
  //           ^
  // [analyzer] COMPILE_TIME_ERROR.CONST_NOT_INITIALIZED
  // [cfe] The const variable 'a' must be initialized.
  static const b = 3 + 5;
}

main() {
  A.x = 2;
  //^
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_CONST
  // [cfe] Setter not found: 'x'.
  new B();
  print(B.b);
  print(B.a);
}
