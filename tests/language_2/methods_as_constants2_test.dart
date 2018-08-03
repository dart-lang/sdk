// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that a function only used by compile-time constants is being
// generated.

import "package:expect/expect.dart";

topLevelMethod() => 42;

class A {
  final Function f;
  const A(this.f);
}

main() {
  Expect.equals(42, const A(topLevelMethod).f());
}
