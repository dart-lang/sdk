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
// VMOptions=--no_inline_alloc
// VMOptions=--old_gen_heap_size=150

import "dart:ffi";
import "dart:io";

import "splay_common.dart";

void main() {
  if (Platform.isWindows) {
    print("No malloc via self process lookup on Windows");
    return;
  }

  // Split across turns so finalizers can run.
  FinalizerSplay().mainAsync();
}

class FinalizerSplay extends Splay {
  newPayload(int depth, String tag) => Payload.generate(depth, tag);
  Node newNode(num key, Object? value) => new FinalizerNode(key, value);
}

final libc = DynamicLibrary.process();
typedef MallocForeign = Pointer<Void> Function(IntPtr size);
typedef MallocNative = Pointer<Void> Function(int size);
final malloc = libc.lookupFunction<MallocForeign, MallocNative>('malloc');
typedef FreeForeign = Void Function(Pointer<Void>);
final free = libc.lookup<NativeFunction<FreeForeign>>('free');
final freeFinalizer = NativeFinalizer(free);

class Leaf implements Finalizable {
  final Pointer<Void> memory;

  Leaf(String tag) : memory = malloc(15) {
    if (memory == nullptr) {
      throw OutOfMemoryError();
    }
    freeFinalizer.attach(this, memory, detach: this, externalSize: 15);
  }
}

class Payload {
  Payload(this.left, this.right);
  var left, right;

  static generate(depth, tag) {
    if (depth == 0) return new Leaf(tag);
    return new Payload(generate(depth - 1, tag), generate(depth - 1, tag));
  }
}

class FinalizerNode extends Node {
  FinalizerNode(num key, Object? value) : super(key, value);

  Node? left, right;
}
