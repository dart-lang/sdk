// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--async_igoto_threshold=0 --optimization_counter_threshold=10 --deterministic

// Regression test for https://github.com/flutter/flutter/issues/51298.
// This would cause a crash due to bad offsets causing entry to hit the pre-code
// barrier of int3s.

import 'dart:async';

Iterable<bool> state_machine() sync* {
  bool a = true;

  for (var i = 0; i < 2; i++) {
    switch (a) {
      case true:
        a = false;
        break;
    }
  }

  switch (a) {
    case false:
      if (!a) {
        yield a;
      }
  }
}

void main() {
  // This would crash due to bad flowgraph entry offsets.
  for (final _ in state_machine()) {}
}
