// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--old_gen_heap_size=20

import "dart:_internal" show intern;

@pragma("vm:never-inline")
use(x) => x;

main() {
  const MB = 1 << 20;
  for (var i = 15 * MB; i < 20 * MB; i++) {
    use(intern((i.toString()))); // Should not hit OutOfMemory
  }
}
