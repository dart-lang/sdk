// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:expect/expect.dart";

typedef void FooFunction(int a, double b);

main() {
  Function expectedError = (e) => e is ArgumentError;

  Expect.throws(() => reflectClass(dynamic), expectedError);
  Expect.throws(() => reflectClass(1), expectedError); //# 01: compile-time error
  Expect.throws(() => reflectClass("string"), expectedError); //# 02: compile-time error
  Expect.throws(() => reflectClass(FooFunction), expectedError);
}
