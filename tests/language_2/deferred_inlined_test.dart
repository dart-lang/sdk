// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10

// Declares foo that returns 42.
import "deferred_constraints_lib2.dart" deferred as lib;

import 'package:expect/expect.dart';

bool libLoaded = false;

main() {
  Expect.equals(88, heyhey());

  // Trigger optimization of 'hehey' which inlines 'barbar'.
  for (int i = 0; i < 30000; i++) {
    heyhey();
  }

  lib.loadLibrary().then((_) {
    libLoaded = true;
    Expect.equals(42, heyhey());
  });
}

// Inline bar in optimized code.
heyhey() => barbar();

barbar() {
  if (libLoaded) {
    // Returns 42.
    return lib.foo();
  }
  return 88;
}
