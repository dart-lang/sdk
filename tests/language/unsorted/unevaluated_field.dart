// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that environment constants in field initializers work properly.

import "package:expect/expect.dart";

const int gx =
    const bool.hasEnvironment("x") ? const int.fromEnvironment("x") : null;

class A {
  final int x = gx;
  final int y =
      const bool.hasEnvironment("y") ? const int.fromEnvironment("y") : null;
  const A();
}

main() {
  const a = const A();
  Expect.isTrue(a.x == null || a.x != null);
  Expect.isTrue(a.y == null || a.y != null);
}
