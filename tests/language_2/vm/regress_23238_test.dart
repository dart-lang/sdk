// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  int x = 327680;
  int r = 65536;
  for (var i = 0; i < 200; i++) {
    Expect.equals(r, x ~/ 5);
    x *= 10;
    r *= 10;

    if (x < 0) {
      // Overflow.
      break;
    }
  }
}
