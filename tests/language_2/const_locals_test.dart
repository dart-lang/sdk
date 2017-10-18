// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test of compile time constant local variables.

const N = 8;

class ConstFoo {
  final x;
  const ConstFoo(this.x);
}

main() {
  const MIN = 2 - 1;
  const MAX = N * 2;
  const MASK = (1 << (MAX - MIN + 1)) - 1; // 65535.
  Expect.equals(1, MIN);
  Expect.equals(16, MAX);
  Expect.equals(65535, MASK);
  const s = 'MIN = $MIN  MAX = $MAX  MASK = $MASK';
  Expect.identical(s, 'MIN = $MIN  MAX = $MAX  MASK = $MASK');
  Expect.equals("MIN = 1  MAX = 16  MASK = 65535", s);
  var cf1 = const ConstFoo(MASK);
  var cf2 = const ConstFoo(s);
  var cf3 = const ConstFoo('MIN = $MIN  MAX = $MAX  MASK = $MASK');
  Expect.identical(cf2, cf3);
  Expect.isFalse(identical(cf2, cf1));
}
