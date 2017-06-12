// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--optimization-counter-threshold=100 --no-background-compilation

import "deferred_load_inval_code_lib.dart" deferred as d;

bool loaded = false;

var x = 0;

bla() {
  if (loaded) {
    // Loading the library should have invalidated the optimized
    // code containing the NSME. Now expect this call to succeed.
    d.foo();
  } else {
    // Do some "busy work" to trigger optimization.
    for (var i = 0; i < 100; i++) {
      x++;
    }
  }
}

warmup() {
  for (int i = 1; i < 1000; i++) {
    bla();
  }
}

main() {
  warmup();
  d.loadLibrary().then((_) {
    loaded = true;
    bla();
  });
}
