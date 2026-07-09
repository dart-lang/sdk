// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for crash https://github.com/dart-lang/sdk/issues/59822
//
// VMOptions= --optimization_counter_threshold=1 --deterministic

@pragma('vm:never-inline')
void use(Object? v) {}

@pragma('vm:never-inline')
void foo(bool a, bool b) {
  String v = "a";
  try {
    if (a) {
      if (b) {
        // Live assignment which flows out of the block.
        v = "b";
      }
      // Last use of `v` the variable is dead after this point.
      use(v); // (1)
    }
    use(0); // (2)
  } catch (e) {
    // `v` is not live into the catch. Notice that different values of `v`
    // will flow on exception edges: from (1) phi("a", "b") flows but from
    // (2) optimized out value flows because `v` is dead at that point and
    // pruned from the environment. This means TCO pass should not be able
    // to remove Parameter corresponding to v by itself - but such
    // Parameter should not be inserted by SSA construction either.
  }
}

void main() {
  foo(true, true);
  foo(true, true);
}
