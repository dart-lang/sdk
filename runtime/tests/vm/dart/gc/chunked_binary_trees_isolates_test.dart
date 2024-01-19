// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--verify_store_buffer
// VMOptions=--verify_after_marking
// VMOptions=--runtime_allocate_old
// VMOptions=--runtime_allocate_spill_tlab
// VMOptions=--no_inline_alloc

// Stress test for write barrier elimination that leaves many stores with
// eliminated barriers that create the only reference to an object in flight at
// the same time.

import "dart:isolate";
import "chunked_binary_trees_test.dart" as test;

child(port) {
  test.main();
  port.send("done");
}

main() {
  for (var i = 0; i < 2; i++) {
    var port;
    port = new RawReceivePort((_) {
      port.close();
    });
    Isolate.spawn(child, port.sendPort);
  }
}
