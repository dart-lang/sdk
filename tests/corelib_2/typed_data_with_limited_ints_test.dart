// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--limit-ints-to-64-bits --optimization_counter_threshold=10 --no-background-compilation

// Test for dart:typed_data (in particular, ByteData.get/setUint64 and
// UInt64List) in --limit-ints-to-64-bits mode (with limited 64-bit integers).

import 'dart:typed_data';
import "package:expect/expect.dart";

testByteData() {
  ByteData data = new ByteData(17);

  data.setInt64(5, -0x1122334455667788);
  Expect.equals(-0x1122334455667788, data.getUint64(5));

  data.setUint32(5, 0x10203040);
  Expect.equals(0x10203040aa998878, data.getUint64(5));

  data.setUint64(3, -1);
  Expect.equals(-1, data.getInt64(3));

  data.setUint64(7, 0x7fedcba987654321);
  Expect.equals(0x7fedcba987654321, data.getInt64(7));
}

testUint64List() {
  Uint64List u64 = new Uint64List(3);
  Int64List i64 = new Int64List.view(u64.buffer);

  i64[0] = 0x7fffffffffffffff;
  i64[1] = -1;
  i64[2] = 42;

  Expect.equals(0x7fffffffffffffff, u64[0]);
  Expect.equals(-1, u64[1]);
  Expect.equals(42, u64[2]);

  u64[0] = -900000000000000;
  Expect.equals(-900000000000000, i64[0]);
}

main() {
  for (int i = 0; i < 20; i++) {
    testByteData();
    testUint64List();
  }
}
