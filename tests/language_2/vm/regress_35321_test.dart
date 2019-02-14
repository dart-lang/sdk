// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Proper CP on double op (dartbug.com/35321).
//
// VMOptions=--deterministic --optimization_counter_threshold=10

import "package:expect/expect.dart";

double foo(bool x) {
  if (x) return 1.0;
}

int bar(int i) {
  if (i < 0) {
    return bar(i + 1);
  } else if ((foo(i == 22) / 22.0) >= (1 / 0.0)) {
    return 1;
  }
  return 0;
}

void main() {
  for (int i = 0; i < 20; ++i) {
    var x = -1;
    try {
      x = bar(i);
    } catch (_) {
      x = -2;
    }
    Expect.equals(-2, x);
  }
}
