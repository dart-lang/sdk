// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is a derivative of the Splay benchmark that is run with a variety
// of different GC options. It makes for a good GC stress test because it
// continuously makes small changes to a large, long-lived data structure,
// stressing lots of combinations of references between new-gen and old-gen
// objects, and between marked and unmarked objects.

// VMOptions=
// VMOptions=---no_concurrent_mark --no_concurrent_sweep
// VMOptions=---no_concurrent_mark --concurrent_sweep
// VMOptions=---no_concurrent_mark --use_compactor
// VMOptions=---no_concurrent_mark --use_compactor --force_evacuation
// VMOptions=---concurrent_mark --no_concurrent_sweep
// VMOptions=---concurrent_mark --concurrent_sweep
// VMOptions=---concurrent_mark --use_compactor
// VMOptions=---concurrent_mark --use_compactor --force_evacuation
// VMOptions=---verify_before_gc
// VMOptions=---verify_after_gc
// VMOptions=---verify_before_gc --verify_after_gc
// VMOptions=---verify_store_buffer
// VMOptions=---verify_after_marking
// VMOptions=---runtime_allocate_old
// VMOptions=---runtime_allocate_spill_tlab
// VMOptions=---no_inline_alloc

import "dart:isolate";
import "splay_test.dart" as test;

void main() {
  for (var i = 0; i < 2; i++) {
    var port;
    port = new RawReceivePort((_) {
      port.close();
    });
    Isolate.spawn(child, port.sendPort);
  }
}

void child(port) {
  test.main();
  port.send("Done");
}
