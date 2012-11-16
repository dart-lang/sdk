// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that SSA values are correctly numbered after inlining that adds
// constants to original environment.

h(x, y) => x == y;

g(y, [x0 = 0, x1 = 1, x2 = 2, x3 = 3]) => y + x0 + x1 + x2 + x3;

f(y) => h(y, g(y));

main() {
  for (var i = 0; i < 1000; i++) f(i);
}
