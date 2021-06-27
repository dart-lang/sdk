// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10  --no-background-compilation

// @dart = 2.9

import "package:expect/expect.dart";

dynamic a() {
  return 23;
}

dynamic b() {
  return 26;
}

@pragma("vm:never-inline")
dynamic foo() {
  // BinarySmiOp(<<) marked truncating
  return (a() << b()) & 0xFFFFFFF;
}

main() {
  for (var i = 0; i < 20; i++) {
    Expect.equals(201326592, foo());
  }
}
