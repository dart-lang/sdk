// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.
// VMOptions=--optimization-counter-threshold=10 --checked

// This test crashes if we recompute type of AssertAssignableInstr based on its
// output types. By doing that we would eliminate not only the unnecessary
// AssertAssignableInstr but also the trailing class check.

main() {
  // Foul up  IC data in integer's unary minus.
  var y = -0x80000000;
  testInt64List();
}

testInt64List() {
  var array = new List(10);
  testInt64ListImpl(array);
}

testInt64ListImpl(array) {
  for (int i = 0; i < 10; ++i) {}
  int sum = 0;
  for (int i = 0; i < 10; ++i) {
    array[i] = -0x80000000000000 + i;
  }
}
