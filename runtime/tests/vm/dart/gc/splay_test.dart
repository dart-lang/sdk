// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is a derivative of the Splay benchmark that is run with a variety
// of different GC options. It makes for a good GC stress test because it
// continuously makes small changes to a large, long-lived data structure,
// stressing lots of combinations of references between new-gen and old-gen
// objects, and between marked and unmarked objects.

// VMOptions=
// VMOptions=--profiler --no_concurrent_mark --no_concurrent_sweep
// VMOptions=--profiler --no_concurrent_mark --concurrent_sweep
// VMOptions=--profiler --no_concurrent_mark --use_compactor
// VMOptions=--profiler --no_concurrent_mark --use_compactor --force_evacuation
// VMOptions=--profiler --concurrent_mark --no_concurrent_sweep
// VMOptions=--profiler --concurrent_mark --concurrent_sweep
// VMOptions=--profiler --concurrent_mark --use_compactor
// VMOptions=--profiler --concurrent_mark --use_compactor --force_evacuation
// VMOptions=--profiler --scavenger_tasks=0
// VMOptions=--profiler --scavenger_tasks=1
// VMOptions=--profiler --scavenger_tasks=2
// VMOptions=--profiler --scavenger_tasks=3
// VMOptions=--profiler --verify_before_gc
// VMOptions=--profiler --verify_after_gc
// VMOptions=--profiler --verify_before_gc --verify_after_gc
// VMOptions=--profiler --verify_store_buffer
// VMOptions=--profiler --verify_after_marking
// VMOptions=--profiler --stress_write_barrier_elimination
// VMOptions=--profiler --no_inline_alloc
// VMOptions=--profiler --old_gen_heap_size=100
// VMOptions=--profiler --mark_when_idle
// VMOptions=--profiler --no_load_cse
// VMOptions=--profiler --no_dead_store_elimination
// VMOptions=--profiler --no_load_cse --no_dead_store_elimination
// VMOptions=--profiler --test_il_serialization
// VMOptions=--profiler --dontneed_on_sweep

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
    return new Payload(generate(depth - 1, tag),
                       generate(depth - 1, tag));
  }
}

class StrongNode extends Node {
  StrongNode(num key, Object? value) : super(key, value);

  Node? left, right;
}
