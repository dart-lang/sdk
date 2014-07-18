// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10

import 'package:expect/expect.dart';

class Good {
  use(x) { return x & 0x1; }
}

class Bad {
  use(x) { return x & 0x100000000; }
}

f(o, x) => o.use(x << 1);

main() {
  final good = new Good();
  final bad = new Bad();
  for (var i = 0; i < 20000; i++) {
    Expect.equals(0, f(good, 0x80000000));
  }
  Expect.equals(0x100000000, f(bad, 0x80000000));
}

