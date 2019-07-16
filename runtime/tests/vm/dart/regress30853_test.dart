// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dartbug.com/30853: check that we assign correct range
// to Uint32 operations when creating them from Int64 operations.

// VMOptions=--optimization_counter_threshold=50 --no-background-compilation --enable-inlining-annotations

import "package:expect/expect.dart";

const NeverInline = "NeverInline";
const AlwaysInline = "AlwaysInline";

@NeverInline
noop(x) => x;

const int BITS32 = 0xFFFFFFFF;

@AlwaysInline
int toUint32(int x) => noop(x & BITS32);

@NeverInline
bitNotAsUint32(x) {
  // After inlining we will have here BoxUint32(UnboxUint32(UnarySmiOp(~, x)))
  // UnboxUint32 must have correct range assigned, otherwise we will not
  // emit boxing slowpath and Uint32 4294967294 will become Int32 -2 instead.
  return toUint32(~x);
}

main() {
  for (var i = 0; i < 100; i++) {
    Expect.equals(0xfffffffe, bitNotAsUint32(1));
  }
}
