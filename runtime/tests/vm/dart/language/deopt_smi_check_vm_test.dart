// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test deoptimization on a smi check.
// VMOptions=--optimization-counter-threshold=10  --no-background-compilation

import 'package:expect/expect.dart';

hc(a) {
  var r = a.hashCode;
  return r;
}

main() {
  for (var i = 0; i < 20; i++) {
    Expect.equals((1).hashCode, hc(1));
  }
  // Passing double causes deoptimization.
  Expect.equals((1.0).hashCode, hc(1.0));
}
