// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Issue https://github.com/dart-lang/sdk/issues/50537

import "dart:async";
import "dart:ffi";
import "dart:io";

final libc = DynamicLibrary.process();
typedef MallocForeign = Pointer<Void> Function(IntPtr size);
typedef MallocNative = Pointer<Void> Function(int size);
final malloc = libc.lookupFunction<MallocForeign, MallocNative>('malloc');
typedef FreeForeign = Void Function(Pointer<Void>);
final free = libc.lookup<NativeFunction<FreeForeign>>('free');
final freeFinalizer = NativeFinalizer(free);

class Resource implements Finalizable {
  Pointer<Void> _target;
  Resource() : _target = malloc(8) {
    if (_target == nullptr) {
      throw OutOfMemoryError();
    }
    freeFinalizer.attach(this, _target, detach: this, externalSize: 8);
  }
}

void main() {
  if (Platform.isWindows) {
    print("No malloc via self process lookup on Windows");
    return;
  }

  // Split across turns so the internal finalizer cleanup can run.
  // Cf. https://github.com/dart-lang/sdk/issues/50570
  final sw = Stopwatch()..start();
  step() {
    if (sw.elapsedMilliseconds < 2000) {
      // VM assertion: external size of each generation should always be
      // non-negative.
      List.generate(1000, (_) => new Resource());
      Timer.run(step);
    }
  }

  Timer.run(step);
}
