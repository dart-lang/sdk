// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.16

// ignore_for_file: unused_local_variable

import 'dart:ffi';

class MyFinalizable implements Finalizable {
  int _internalValue = 4;

  int Function() capturingThis() {
    return () {
      final result = this._internalValue;
      // Should generate: _reachabilityFence(this)
      return result;
    };
    // Should generate: _reachabilityFence(this)
  }

  int Function() capturingThis2() {
    return () {
      return this._internalValue;
      // Should generate: _reachabilityFence(this)
    };
    // Should generate: _reachabilityFence(this)
  }

  int Function() capturingThis3() {
    return () {
      return _internalValue;
      // Should generate: _reachabilityFence(this)
    };
    // Should generate: _reachabilityFence(this)
  }

  /// Tests that captures later in the body also cause fences earlier in the body.
  int Function() capturingThis4() {
    return () {
      if (DateTime.now().millisecondsSinceEpoch == 42) {
        // Should generate: _reachabilityFence(this)
        return 3;
      }
      return _internalValue;
      // Should generate: _reachabilityFence(this)
    };
    // Should generate: _reachabilityFence(this)
  }
}

void main() {}
