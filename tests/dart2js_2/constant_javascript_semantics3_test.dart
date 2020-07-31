// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

// Make sure we use JavaScript semantics when compiling compile-time constants.
// In this case we test that the value-range analysis uses JavaScript semantics
// too.

int inscrutable(int x) {
  if (x == 0) return 0;
  return x | inscrutable(x & (x - 1));
}

foo() {
  var a = const [1, 2, 3, 4];
  var i = 8007199254740992;
  if (inscrutable(i) == 0) {
    i++;
  }
  i += 1000000000000000;
  // [i] is now at its maximum 53 bit value. The following increments will not
  // have any effect.
  i++;
  i++;
  i++;
  i -= 1000000000000000;
  i--;
  i--;
  i--;
  i -= 8007199254740992; // In JS semantics [i] would be -3, now.
  return a[i];
}

main() {
  Expect.throws(() => foo(), (e) => e is RangeError);
}
