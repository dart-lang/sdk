// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2js regression test where the SSA backend would use the wrong
// type for an instruction: when doing a speculative type propagation,
// if an instruction gets analyzed multiple times, we used to save the
// last inferred type, which could be speculative, instead of the
// first inferred type, which is the actual, non-speculative, type.
//
// Because we are doing speculative type propagation at the very end,
// before emitting the bailout version, the only place where we might
// do wrong optimizations is during the codegen. It turns out that the
// codegen optimizes '==' comparisons on null to '===' in case it knows
// the receiver cannot be null. So in the following example, the
// [:e == null:] comparison in [foo] got wrongly generated to a
// JavaScript identity check (that is, using '==='). But this
// comparison does not work for undefined, which the DOM sometimes
// returns.

import "native_testing.dart";

var a = 42;
var b = 0;

foo(e) {
  // Loop to force a bailout.
  for (int i = 0; i < b; i++) {
    a = e[i]; // Will desire a readable primitive.
  }
  // Our heuristics for '==' on an indexable primitive is that it's
  // more common to do it on string, so we'll want e to be a string.
  return a == e || e == null;
}

main() {
  Expect.isTrue(foo(JS('', 'void 0')));
}
