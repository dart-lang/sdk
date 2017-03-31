// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test various optimizations and deoptimizations of optimizing compiler..
// VMOptions=--enable-inlining-annotations --no-background-compilation --optimization-counter-threshold=1000

import "package:expect/expect.dart";
import "dart:typed_data";

const noInline = "NeverInline";
const alwaysInline = "AlwaysInline";

var list = new Uint32List(1);

@noInline
testuint32(bool b) {
  var t;
  if (b) {
    t = list[0];
  }
  if (t != null) {
    return t & 0x7fffffff;
  }
  return -1;
}

main() {
  var s = 0;
  testuint32(true);
  testuint32(false);
  for (int i = 0; i < 10000; ++i) {
    testuint32(true);
  }
  Expect.equals(0, testuint32(true));
  Expect.equals(-1, testuint32(false));
}
