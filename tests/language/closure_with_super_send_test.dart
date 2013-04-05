// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test a closurized super send.

class Super {
  m() => "super";
}

class Sub extends Super {
  m() => "sub";

  test() {
    var x;
    [0].forEach((e) => x = super.m());
    return x;
  }
}

main() {
  Expect.equals("super", new Sub().test());
  Expect.equals("super", new Super().m());
  Expect.equals("sub", new Sub().m());
}
