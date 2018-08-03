// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--old_gen_heap_size=50

// Test that non-capturing closures don't retain unnecessary memory.
// It tests that the context of `f` allocated within `bar` not leaking and does
// not become the context of empty non-capturing closure allocated inside `foo`.
// If failing it crashes with an OOM error.

import "package:expect/expect.dart";

foo() {
  return () {};
}

bar(a, b) {
  f() => [a, b];
  return foo();
}

main() {
  var closure = null;
  for (var i = 0; i < 100; i++) {
    closure = bar(closure, new List(1024 * 1024));
  }
  Expect.isTrue(closure is Function);
}
