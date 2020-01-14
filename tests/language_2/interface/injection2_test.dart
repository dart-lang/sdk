// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The removed language feature "interface injection" is now a syntax error.

import "package:expect/expect.dart";

abstract class S { }
class C { }
class C implements S;
//    ^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [cfe] 'C' is already declared in this scope.
//                 ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] A class declaration must have a body, even if it is empty.
//                  ^
// [analyzer] SYNTACTIC_ERROR.UNEXPECTED_TOKEN
// [cfe] Unexpected token ';'.

main() {
  Expect.isFalse(new C() is S);
  //                 ^
  // [cfe] Method not found: 'C'.
}
