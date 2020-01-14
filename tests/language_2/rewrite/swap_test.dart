// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

swap1(x, y, b) {
  if (b) {
    var t = x;
    x = y;
    y = t;
  }
  Expect.equals(2, x);
  Expect.equals(1, y);
}

swap2(x, y, z, w, b) {
  if (b) {
    var t = x;
    x = y;
    y = t;

    var q = z;
    z = w;
    w = q;
  }
  Expect.equals(2, x);
  Expect.equals(1, y);
  Expect.equals(4, z);
  Expect.equals(3, w);
}

swap3(x, y, z, b) {
  if (b) {
    var t = x;
    x = y;
    y = z;
    z = t;
  }
  Expect.equals(2, x);
  Expect.equals(3, y);
  Expect.equals(1, z);
}

swap4(x, y, z, b) {
  if (b) {
    var t = x;
    x = y;
    y = z; // swap cycle involves unused variable 'y'
    z = t;
  }
  Expect.equals(2, x);
  Expect.equals(1, z);
}

swap5(x, y, z, w, b, b2) {
  if (b) {
    var t = x;
    x = y;
    y = t;
  }
  if (b2) {
    var q = z;
    z = w;
    w = q;
  }
  Expect.equals(2, x);
  Expect.equals(1, y);
  Expect.equals(4, z);
  Expect.equals(3, w);
}

main() {
  swap1(1, 2, true);
  swap1(2, 1, false);

  swap2(1, 2, 3, 4, true);
  swap2(2, 1, 4, 3, false);

  swap3(1, 2, 3, true);
  swap3(2, 3, 1, false);

  swap4(1, 2, 3, true);
  swap4(2, 3, 1, false);

  swap5(1, 2, 3, 4, true, true);
  swap5(1, 2, 4, 3, true, false);
  swap5(2, 1, 3, 4, false, true);
  swap5(2, 1, 4, 3, false, false);
}
