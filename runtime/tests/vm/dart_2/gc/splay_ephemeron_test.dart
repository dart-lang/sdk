// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is a derivative of the Splay benchmark that is run with a variety
// of different GC options. It makes for a good GC stress test because it
// continuously makes small changes to a large, long-lived data structure,
// stressing lots of combinations of references between new-gen and old-gen
// objects, and between marked and unmarked objects.
// The ephemeron variant of this test replaces the direct child pointers in the
// tree with Expandos to stress the handling of WeakProperties/ephemerons.

// This file is copied into another directory and the default opt out scheme of
// CFE using the pattern 'vm/dart_2' doesn't work, so opt it out explicitly.
// @dart=2.9

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
// VMOptions=--runtime_allocate_old
// VMOptions=--runtime_allocate_spill_tlab
// VMOptions=--no_inline_alloc
// VMOptions=--old_gen_heap_size=150

import "splay_common.dart";

void main() {
  EphemeronSplay().main();
}

class EphemeronSplay extends Splay {
  newPayload(int depth, String tag) => Payload.generate(depth, tag);
  Node newNode(num key, Object value) => new EphemeronNode(key, value);
}

class Payload {
  Payload(left, right) {
    this.left = left;
    this.right = right;
  }

  // This ordering of fields is deliberate: one key is visited before the
  // expando and one after.
  final leftKey = new Object();
  final expando = new Expando();
  final rightKey = new Object();

  get left => expando[leftKey];
  set left(value) => expando[leftKey] = value;
  get right => expando[rightKey];
  set right(value) => expando[rightKey] = value;

  static generate(depth, tag) {
    if (depth == 0) return new Leaf(tag);
    return new Payload(generate(depth - 1, tag),
                       generate(depth - 1, tag));
  }
}

class EphemeronNode extends Node {
  EphemeronNode(num key, Object value) : super(key, value);

  // This ordering of fields is deliberate: one key is visited before the
  // expando and one after.
  final leftKey = new Object();
  final expando = new Expando<Node>();
  final rightKey = new Object();

  Node get left => expando[leftKey];
  set left(Node value) => expando[leftKey] = value;
  Node get right => expando[rightKey];
  set right(Node value) => expando[rightKey] = value;
}
