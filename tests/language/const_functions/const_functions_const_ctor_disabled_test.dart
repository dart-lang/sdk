// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests const constructors with a body are disabled without const functions.

import "package:expect/expect.dart";

const printString = "print";
const var1 = Simple(printString);
//           ^
// [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
class Simple {
  final String name;

  const Simple(this.name) {
//^
// [cfe] A const constructor can't have a body.
//                        ^
// [analyzer] SYNTACTIC_ERROR.CONST_CONSTRUCTOR_WITH_BODY
    assert(this.name == printString);
  }
}
