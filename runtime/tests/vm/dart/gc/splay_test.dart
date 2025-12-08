// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is a derivative of the Splay benchmark that is run with a variety
// of different GC options. It makes for a good GC stress test because it
// continuously makes small changes to a large, long-lived data structure,
// stressing lots of combinations of references between new-gen and old-gen
// objects, and between marked and unmarked objects.

// VMOptions=
// VMOptions=--no_concurrent_mark --no_concurrent_sweep
// VMOptions=--no_concurrent_mark --concurrent_sweep
// VMOptions=--no_concurrent_mark --use_compactor
// VMOptions=--no_concurrent_mark --use_compactor --force_evacuation
// VMOptions=--concurrent_mark --no_concurrent_sweep
// VMOptions=--concurrent_mark --concurrent_sweep
// VMOptions=--concurrent_mark --use_compactor
// VMOptions=--concurrent_mark --use_compactor --force_evacuation
// VMOptions=--scavenger_tasks=-1
// VMOptions=--scavenger_tasks=1
// VMOptions=--scavenger_tasks=2
// VMOptions=--verify_before_gc
// VMOptions=--verify_after_gc
// VMOptions=--verify_before_gc --verify_after_gc
// VMOptions=--verify_store_buffer
// VMOptions=--verify_after_marking
// VMOptions=--runtime_allocate_old
// VMOptions=--runtime_allocate_spill_tlab
// VMOptions=--no_inline_alloc
// VMOptions=--old_gen_heap_size=100
// VMOptions=--mark_when_idle
// VMOptions=--no_load_cse
// VMOptions=--no_dead_store_elimination
// VMOptions=--no_load_cse --no_dead_store_elimination
// VMOptions=--test_il_serialization
// VMOptions=--dontneed_on_sweep
// VMOptions=--sim_buffer_memory

import "splay_common.dart";

void main() {
  StrongSplay().main();
}

class StrongSplay extends Splay {
  Object newPayload(int depth, String tag) => Payload.generate(depth, tag);
  Node newNode(num key, Object? value) => new StrongNode(key, value);
}

class Payload {
  Payload(this.left, this.right);
  var left, right;

  static generate(depth, tag) {
    if (depth == 0) return new Leaf(tag);
    return new Payload(generate(depth - 1, tag), generate(depth - 1, tag));
  }
}

class StrongNode extends Node {
  StrongNode(num key, Object? value) : super(key, value);

  Node? left, right;
}
