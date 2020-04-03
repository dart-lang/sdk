// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// This program tripped dart2js.
main() {
  var a = 1;
  var b = 2;
  var c = 3;
  var d = 4;
  var e = 5;
  for (int i = 0; i < 2; i++) {
    if (i == 1) {
      Expect.equals(4, e);
      Expect.equals(3, d);
      Expect.equals(8, c);
      Expect.equals(1, b);
      Expect.equals(32, a);
    }
    int f;
    int k;
    if (i < 20) {
      f = b & c | ~b & d;
      k = 0x5A827999;
    } else if (i < 40) {
      f = b ^ c ^ d;
      k = 0x6ED9EBA1;
    } else if (i < 60) {
      f = b & c | b & d | c & d;
      k = 0x8F1BBCDC;
    } else {
      f = b ^ c ^ d;
      k = 0xCA62C1D6;
    }

    int temp = a << 5;
    e = d;
    d = c;
    c = b << 2;
    b = a;
    a = temp;
  }
}
