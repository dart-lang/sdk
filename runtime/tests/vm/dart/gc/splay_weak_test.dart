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
// VMOptions=--scavenger_tasks=0
// VMOptions=--scavenger_tasks=1
// VMOptions=--scavenger_tasks=2
// VMOptions=--scavenger_tasks=3
// VMOptions=--verify_before_gc
// VMOptions=--verify_after_gc
// VMOptions=--verify_before_gc --verify_after_gc
// VMOptions=--verify_store_buffer
// VMOptions=--verify_after_marking
// VMOptions=--stress_write_barrier_elimination
// VMOptions=--no_eliminate_write_barriers
// VMOptions=--no_inline_alloc
// VMOptions=--old_gen_heap_size=150

import "splay_common.dart";

void main() {
  WeakSplay().main();
}

class WeakSplay extends Splay {
  newPayload(int depth, String tag) => Payload.generate(depth, tag);
  Node newNode(num key, Object? value) => new WeakNode(key, value);
}

class Payload {
  Payload(left, right) {
    this.left = left;
    this.right = right;
  }

  // This ordering of fields is deliberate: one strong reference visited before
  // the weak reference and one after.
  var leftWeak;
  @pragma("vm:entry-point") // TODO(50571): Remove illegal optimization.
  var leftStrong;
  @pragma("vm:entry-point") // TODO(50571): Remove illegal optimization.
  var rightStrong;
  var rightWeak;

  get left => leftWeak?.target;
  set left(value) {
    leftWeak = new WeakReference(value as Object);
    // Indirection: chance for WeakRef to be scanned before target is marked.
    leftStrong = [[value]];
  }

  get right => rightWeak?.target;
  set right(value) {
    rightWeak = new WeakReference(value as Object);
    // Indirection: chance for WeakRef to be scanned before target is marked.
    rightStrong = [[value]];
  }

  static generate(depth, tag) {
    if (depth == 0) return new Leaf(tag);
    return new Payload(generate(depth - 1, tag), generate(depth - 1, tag));
  }
}

class WeakNode extends Node {
  WeakNode(num key, Object? value) : super(key, value);

  // This ordering of fields is deliberate: one strong reference visited before
  // the weak reference and one after.
  var leftWeak;
  @pragma("vm:entry-point") // TODO(50571): Remove illegal optimization.
  var leftStrong;
  @pragma("vm:entry-point") // TODO(50571): Remove illegal optimization.
  var rightStrong;
  var rightWeak;

  Node? get left => leftWeak?.target;
  set left(Node? value) {
    leftWeak = value == null ? null : new WeakReference(value);
    // Indirection: chance for WeakRef to be scanned before target is marked.
    leftStrong = [[value]];
  }

  Node? get right => rightWeak?.target;
  set right(Node? value) {
    rightWeak = value == null ? null : new WeakReference(value);
    // Indirection: chance for WeakRef to be scanned before target is marked.
    rightStrong = [[value]];
  }
}
