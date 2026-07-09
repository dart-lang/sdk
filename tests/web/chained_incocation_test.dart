// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

/// Regression test for some DDC timeouts while compiling when handling very
/// long chains of instance invocations.

void main() {
  var fn = () => C()
      .foo()
      .bar()
      .foo()
      .bar()
      .foo()
      .bar()
      .foo()
      .bar()
      .foo()
      .bar()
      .foo()
      .bar()
      .foo()
      .bar()
      .foo()
      .bar()
      .foo()
      .bar()
      .foo()
      .bar()
      .baz();

  var x = fn();
  Expect.equals(x, 10);
}

class C {
  C foo() => C();
  C bar() => C();
  int baz() => 10;
}
