// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test optimization of modulo oeprator on Smi.


main() {
  for (int i = -3000; i < 3000; i++) {
    Expect.equals(i % 256, foo(i));
    Expect.equals(i % -256, boo(i));
    try {
      hoo(i);
      Expect.fail("Exception expected.");
    } catch (e) {}
  }
}

foo(i) {
  return i % 256;  // This will get optimized to AND instruction.
}


boo(i) {
  return i % -256;
}


hoo(i) {
  return i % 0;
}
