// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  const A(
    this.x,
    //   ^
    // [analyzer] COMPILE_TIME_ERROR.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR
    // [cfe] 'x' is a final instance variable that was initialized at the declaration.
  );
  final x = null;
}

class B extends A {
  const B();
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS
  // [cfe] The implicitly called unnamed constructor from 'A' has required parameters.
}

var b = const B();

main() {
  Expect.equals(null, b.x);
}
