// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=1 --deterministic

// Regression test for https://github.com/dart-lang/sdk/issues/39520.
// Verifies that an attempt to inline SIMD shuffle operation doesn't
// result in incorrect IL.

import "package:expect/expect.dart";
import 'dart:typed_data';

class Foo {
  bar() {
    return Float32x4.zero().shuffleMix(Float32x4.zero(), -3);

    // Although this code is unreachable, context is allocated
    // for this closure. Context allocation is handled by
    // allocation sinking, which explodes if an attempt to inline
    // shuffleMix clobbered IL.
    baz() => this;
  }
}

main() {
  Expect.throwsRangeError(() => new Foo().bar());
}
