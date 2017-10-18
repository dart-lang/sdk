// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Unresolved imported symbols are errors.
// In this test, the function myFunc contains malformed types because
// lib12.Library13 is not resolved.

import "package:expect/expect.dart";
import "library12.dart" as lib12;

typedef
    lib12.Library13     //# 00: compile-time error
    myFunc(
        lib12.Library13 //# 00: continued
        param);
typedef
    lib12.Library13     //# 01: compile-time error
    myFunc2(
        lib12.Library13 //# 01: continued
        param, int i);

main() {
  Expect.isTrue(((Object x) => x) is myFunc);
  Expect.isTrue(((Object x, int y) => x) is myFunc2);
  Expect.isFalse(((Object x, String y) => x) is myFunc2);
}
