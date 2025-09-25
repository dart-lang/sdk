// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

void test() {
  num x;
  for (x = 0; x < 10; x++) {
    if (x is int) {
      var y = x;
    }
  }
}

main() {}
