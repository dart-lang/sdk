// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that optimized Object.hashCode works for the null receiver.
// VMOptions=--optimization_counter_threshold=10 --no-background_compilation

main() {
  for (int i = 0; i < 20; i++) {
    foo(null);
  }
}

foo(a) => a.hashCode;
