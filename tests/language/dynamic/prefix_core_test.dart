// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test explicit import of dart:core in the source code..

library DynamicPrefixCoreTest.dart;

import "package:expect/expect.dart";
import "dart:core" as mycore;

void main() {
  // The built-in type declaration `dynamic`, which is declared in the
  // library `dart:core`, denotes the `dynamic` type. So, in this library
  // it must be reference with the prefix.
  dynamic; //# 01: compile-time error

  Expect.isTrue(mycore.dynamic is mycore.Type); //# 02: ok
}
