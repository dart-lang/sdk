// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dartbug.com/29620: check that decision to deoptimize
// and decisions which parts of the instruction to emit use the same
// range information for instruction inputs.

// VMOptions=--enable-inlining-annotations --optimization_counter_threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

const alwaysInline = "AlwaysInline";
const neverInline = "NeverInline";

class Flag {
  var value;
  Flag(this.value);

  static final FLAG = new Flag(0);
}

@alwaysInline
void checkRange(bit) {
  if (bit < 0 || bit > 31) {
    throw "bit must be in [0, 31]";
  }
}

@alwaysInline
bool isSet(flags, bit) {
  checkRange(bit);
  // Note: > 0 here instead of == 0 to prevent merging into
  // TestSmi instruction.
  return (flags & (1 << bit)) > 0;
}

@neverInline
bool bug(flags) {
  var bit = Flag.FLAG.value;
  checkRange(bit);
  for (var i = 0; i < 1; i++) {
    bit = Flag.FLAG.value;
    checkRange(bit);
  }

  // In early optimization stages `bit` would be a Phi(...). This Phi would be
  // dominated by checkRange and thus range analysis will infer [0, 31] range
  // for it - and thus a EliminateEnvironment will make decision that
  // (1 << bit) can't deoptimize and will detach environment from it. Later
  // passes will eliminate Phi for `bit` as it is redundant and as a result we
  // will loose precise range information for `bit` and backend will try
  // to emit a range check and a deoptimization.
  return isSet(flags, bit);
}

main() {
  for (var i = 0; i < 100; i++) {
    bug(1);
  }
}
