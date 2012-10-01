// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Make sure we use JavaScript semantics when compiling compile-time constants.
// In this case we test that the value-range analysis uses JavaScript semantics
// too.

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

foo() {
  var a = const [1, 2];
  var i = 0x100000000;
  if (inscrutable(i) == 0) {
    i = 0x100000001;
  }
  i = 0xFFFFFFFFF & i;  // In JS semantics [:i:] will be truncated to 32 bits.
  i = 0x100000001 - i;
  return a[i];
}

main() {
  Expect.throws(() => foo(),
                (e) => e is IndexOutOfRangeException);
}
