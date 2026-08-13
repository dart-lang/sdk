// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10 --no-background_compilation

import 'package:expect/expect.dart';

trunc(x) => x & 0xFFFFFFFF;

foo(t, x) => t(x >> 15);

main() {
  for (var i = 0; i < 20000; i++) {
    Expect.equals(0x00010000, foo(trunc, 0x80000000));
  }
  for (var i = 0; i < 20000; i++) {
    Expect.equals(0x10000000, foo(trunc, 0x80000000000));
  }
}
