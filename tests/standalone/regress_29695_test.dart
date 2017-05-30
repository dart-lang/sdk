// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that type tests are not misoptimized.
// VMOptions=--optimization-counter-threshold=1000 --optimization-filter=IsAnInt

main() {
  train();
  if (IsAnInt("This is not an int")) throw "oops";
}

// Prime the IC with things that are and are not ints.
void train() {
  for (int i = 0; i < 10000; i++) {
    IsAnInt(42); // Smi - always goes first in the generated code.
    IsAnInt(1 << 62); // Mint on 64 bit platforms.
    IsAnInt(1 << 62);
    IsAnInt(4200000000000000000000000000000000000); // BigInt
    IsAnInt(4200000000000000000000000000000000000);
    // This one that is not an int goes last in the IC because it is called
    // less frequently.
    IsAnInt(4.2);
  }
}

bool IsAnInt(f) => f is int;
