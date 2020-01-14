// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test lazy deoptimization from within an inlined function.
// VMOptions=--deoptimize_alot --optimization-counter-threshold=10 --no-use-osr

import "package:expect/expect.dart";

call_native(x) {
  // Wrap in try to avoid inlining.
  // Use a large int so the intrinsifier does not fire.
  try {
    return x + 9223372036854775807;
  } finally {}
}

bar(x) {
  if (x < 0) call_native(x);
  x = 42;
  return x;
}

foo(x) {
  x = bar(x);
  return x;
}

main() {
  Expect.equals(42, foo(1));
  for (var i = 0; i < 20; i++) foo(7);
  Expect.equals(42, foo(2));
  // Call the runtime to trigger lazy deopt with foo/bar on the stack.
  Expect.equals(42, foo(-1));
}
