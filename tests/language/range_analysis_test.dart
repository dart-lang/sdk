// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Checks that range analysis does not enter infinite loop trying to propagate
// ranges through dependant phis.

test() {
  var sum = 0;
  for (var i = 0; i < 10; i++) {
    for (var j = i - 1; j >= 0; j--) {
      for (var k = j; k < i; k++) {
        sum += (i + j + k);
      }
    }
  }
  return sum;
}

main() {
  for (var i = 0; i < 1000; i++) test();
}