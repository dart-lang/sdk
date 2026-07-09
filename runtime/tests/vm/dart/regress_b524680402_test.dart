// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that FutureOr<X?> is not treated as non-nullable type in the
// type propagator.

// VMOptions=--optimization-counter-threshold=100 --no-background-compilation

import 'dart:async';

import 'package:expect/expect.dart';

@pragma('vm:never-inline')
int g(Object? x) {
  if (x is FutureOr<int?>) {
    return (x as int?)! + 1;
  }
  return 0;
}

void main() {
  for (int i = 0; i < 200; i++) {
    g(0x7FFFFFFFFFFFFFF0);
  }
  Expect.throws(() {
    g(null);
  });
}
