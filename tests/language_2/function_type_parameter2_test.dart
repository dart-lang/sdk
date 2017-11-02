// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test to check that we can parse closure type formal parameters with
// default value.

import "package:expect/expect.dart";

class FunctionTypeParameterTest {
  static var formatter;

  static SetFormatter([String fmt(int i) = null]) {
    formatter = fmt;
  }

  static void testMain() {
    Expect.equals(null, formatter);
    SetFormatter((i) => "$i");
    Expect.equals(false, null == formatter);
    Expect.equals("1234", formatter(1230 + 4));
    SetFormatter();
    Expect.equals(null, formatter);
  }
}

main() {
  FunctionTypeParameterTest.testMain();
}
