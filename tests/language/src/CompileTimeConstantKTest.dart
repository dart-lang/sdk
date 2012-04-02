// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final x = const { 'a': 3, 'a': 4 };
final y = const { 'a': 10, 'b': 11, 'a': 12, 'b': 13, 'a': 14 };
final z = const { '__proto__': 496,
                  '__proto__': 497,
                  '__proto__': 498,
                  '__proto__': 499 };

final x2 = const { 'a': 4 };
final y2 = const { 'a': 14, 'b': 13 };
final z2 = const { '__proto__': 499 };

main() {
  Expect.identical(x2, x);
  Expect.identical(y2, y);
  Expect.identical(z2, z);
}
