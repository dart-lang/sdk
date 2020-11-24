// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:ffi";

import 'package:ffi/ffi.dart';

/// [Arena] manages allocated C memory.
///
/// Arenas are zoned.
class Arena {
  Arena();

  List<Pointer<Void>> _allocations = [];

  /// Bound the lifetime of [ptr] to this [Arena].
  T scoped<T extends Pointer>(T ptr) {
    _allocations.add(ptr.cast());
    return ptr;
  }

  /// Frees all memory pointed to by [Pointer]s in this arena.
  void finalize() {
    for (final ptr in _allocations) {
      free(ptr);
    }
  }

  /// The last [Arena] in the zone.
  factory Arena.current() {
    return Zone.current[#_currentArena];
  }
}

/// Bound the lifetime of [ptr] to the current [Arena].
T scoped<T extends Pointer>(T ptr) => Arena.current().scoped(ptr);

class RethrownError {
  dynamic original;
  StackTrace originalStackTrace;
  RethrownError(this.original, this.originalStackTrace);
  toString() => """RethrownError(${original})
${originalStackTrace}""";
}

/// Runs the [body] in an [Arena] freeing all memory which is [scoped] during
/// execution of [body] at the end of the execution.
R runArena<R>(R Function(Arena) body) {
  Arena arena = Arena();
  try {
    return runZoned(() => body(arena),
        zoneValues: {#_currentArena: arena},
        onError: (error, st) => throw RethrownError(error, st));
  } finally {
    arena.finalize();
  }
}
