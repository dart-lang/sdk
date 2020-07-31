// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that canonicalization inserts constants with correct representation.
// VMOptions=--optimization-counter-threshold=10 --optimization-filter=bar --no-background-compilation

import 'dart:typed_data';

toSigned(v, width) {
  var signMask = 1 << (width - 1);
  return (v & (signMask - 1)) - (v & signMask);
}

foo(value) {
  return value >> 32;
}

bar(td) {
  return toSigned(foo(td[0]), 64);
}

main() {
  toSigned(1 << 1, 32);
  toSigned(1 << 32, 32);

  var l = new Int64List(1);
  l[0] = 0x78f7f6f5f4f3f2f1;

  for (var i = 0; i < 20; i++) {
    bar(l);
  }
}
