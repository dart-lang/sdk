// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test various optimizations and deoptimizations of optimizing compiler..
// VMOptions=--checked --enable-inlining-annotations --no-background-compilation --optimization-counter-threshold=1000

import "package:expect/expect.dart";

const noInline = "NeverInline";

@noInline
testuint32(y) {
  int x = y;
  if (x != null) {
    return x & 0xffff;
  }
}

main() {
  var s = 0;
  testuint32(0x7fffffff);
  for (int i = 0; i < 10000; ++i) {
    testuint32(i);
  }
  Expect.equals(65535, testuint32(0x7fffffff));
  Expect.equals(65535, testuint32(0x7f3452435245ffff));
}
