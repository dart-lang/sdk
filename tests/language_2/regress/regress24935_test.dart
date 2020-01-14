// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

S() => new Stream.fromIterable([1]);

Future main() async {
  L:
  for (var s = 0; s < 10; s++) {
    await for (var s1 in S()) {
      await for (var s2 in S()) {
        continue L;
      }
    }
  }
  // Regression check: make sure throwing an exception
  // after breaking out of the innermost loop does not
  // crash the VM. In other words, the expected test
  // outcome is an unhandled exception.
  throw "ball"; //# 01: runtime error
}
