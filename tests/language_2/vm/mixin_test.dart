// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Illustrates inlining heuristic issue of
// https://github.com/dart-lang/sdk/issues/37126
// (mixins introduce one extra depth of inlining).

// VMOptions=--deterministic

import "package:expect/expect.dart";

class X {
  const X();
  int foo() {
    return 1;
  }
}

mixin YMixin {
  int bar() {
    return 2;
  }
}

class Y with YMixin {
  const Y();
}

@pragma("vm:never-inline")
int foobar() {
  return new X().foo() + new Y().bar();
}

main() {
  Expect.equals(3, foobar());
}
