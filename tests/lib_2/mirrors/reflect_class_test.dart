// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:expect/expect.dart";

typedef void FooFunction(int a, double b);

main() {
  Expect.throwsArgumentError(() => reflectClass(dynamic));
  Expect.throwsArgumentError(() => reflectClass(1)); //# 01: compile-time error
  Expect.throwsArgumentError(() => reflectClass("string")); //# 02: compile-time error
  Expect.throwsArgumentError(() => reflectClass(FooFunction));
}
