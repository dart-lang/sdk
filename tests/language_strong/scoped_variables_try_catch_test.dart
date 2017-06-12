// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that try/catch does not shadow a variable at runtime.

main() {
  var a = bar();
  try {
    a = bar();
  } catch (e) {}
  Expect.equals(42, a);

  {
    var a = foo();
    try {
      a = foo();
    } catch (e) {}
    Expect.equals(54, a);
  }

  Expect.equals(42, a);
}

bar() => 42;
foo() => 54;
