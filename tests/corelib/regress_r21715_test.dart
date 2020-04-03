// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=5 --no-background_compilation

import "package:expect/expect.dart";

sll(x, shift) => x << shift;

main() {
  for (int i = 0; i < 10; i++) {
    var x = 0x50000000;
    var shift = 34;
    Expect.equals(sll(x, shift), 0x4000000000000000);
  }
}
