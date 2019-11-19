// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=-1 --new_gen_semi_max_size=2

// TODO(rnystrom): This looks like a VM-specific test. Move out of
// tests/language and into somewhere more appropriate.

import 'dart:math';

main() {
  // 2MB / 16 bytes = 125000 allocations

  for (var i = 0; i < 500000; i++) {
    sin(i);
  }

  for (var i = 0; i < 500000; i++) {
    cos(i);
  }

  for (var i = 0; i < 500000; i++) {
    i.toDouble().truncateToDouble();
  }
}
