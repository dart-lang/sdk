// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to infer [:super == null:]
// always returns an int.

import 'package:expect/expect.dart';

class A {
  operator ==(other) => 42;
  //                    ^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  // [cfe] A value of type 'int' can't be returned from a function with return type 'bool'.
}

class B extends A {
  foo() => (super == null) + 4;
  //                       ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '+' isn't defined for the class 'bool'.
}

main() {
  Expect.throwsNoSuchMethodError(() => new B().foo());
}
