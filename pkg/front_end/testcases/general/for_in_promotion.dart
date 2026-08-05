// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from co19/TypeSystem/flow-analysis/reachability_for_in_A02_t07

test(int? n) {
  if (n != null) /* n promoted to `int` */ {
    for (n in [42]) /* n is not promoted not demoted here */ {
      n.isEven; // n is still `int`
    }
    n.isEven;
  }
}

main() {
  test(42);
  test(null);
}
