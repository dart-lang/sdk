// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test inlining of a closure call with constant propagation.
primeForSmis(bool b) {
  smi_op(a, b) => a + b;
  if (b) {
    return smi_op(1, 2);
  } else {
    return smi_op(true, false);
  }
}


main() {
  for (var i=0; i<2000; i++) {
    Expect.equals(3, primeForSmis(true));
  }
}
