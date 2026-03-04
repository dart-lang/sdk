// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for the postfix null assert operator `!`.

import "package:expect/expect.dart";

class C {
  int x;
  C(this.x);
  static C? nullable = C(1);
  C? member() => C(1);
}

main() {
  C nullAssert = .nullable!;
  Expect.equals(1, nullAssert.x);

  C nullAssertChain = .nullable!.member()!;
  Expect.equals(1, nullAssertChain.x);

  bool nullAssertEq = C(1) == .nullable!.member()!;
}
