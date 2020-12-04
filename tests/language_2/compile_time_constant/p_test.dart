// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  const A(
    this.x
    //   ^
    // [analyzer] COMPILE_TIME_ERROR.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR
    // [cfe] 'x' is a final instance variable that was initialized at the declaration.
    //   ^
    // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
      );
  final x = null;
}

class B extends A {
  const B();
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.NO_DEFAULT_SUPER_CONSTRUCTOR
  // [cfe] The superclass, 'A', has no unnamed constructor that takes no arguments.
}

var b = const B();
//      ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_THROWS_EXCEPTION

main() {
  Expect.equals(null, b.x);
}
