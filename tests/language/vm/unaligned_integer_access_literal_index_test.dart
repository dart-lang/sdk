// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10 --no-background_compilation

import 'dart:typed_data';
import 'package:expect/expect.dart';

unalignedUint16() {
  var bytes = new ByteData(64);
  bytes.setUint16(0, 0xABCD);
  Expect.equals(0xABCD, bytes.getUint16(0));
  bytes.setUint16(1, 0xBCDE);
  Expect.equals(0xBCDE, bytes.getUint16(1));
}

unalignedInt16() {
  var bytes = new ByteData(64);
  bytes.setInt16(0, -0x1234);
  Expect.equals(-0x1234, bytes.getInt16(0));
  bytes.setInt16(1, -0x2345);
  Expect.equals(-0x2345, bytes.getInt16(1));
}

unalignedUint32() {
  var bytes = new ByteData(64);
  bytes.setUint32(0, 0xABCDABCD);
  Expect.equals(0xABCDABCD, bytes.getUint32(0));
  bytes.setUint32(1, 0xBCDEBCDE);
  Expect.equals(0xBCDEBCDE, bytes.getUint32(1));
  bytes.setUint32(2, 0xABCDABCD);
  Expect.equals(0xABCDABCD, bytes.getUint32(2));
  bytes.setUint32(3, 0xBCDEBCDE);
  Expect.equals(0xBCDEBCDE, bytes.getUint32(3));
}

unalignedInt32() {
  var bytes = new ByteData(64);
  bytes.setInt32(0, -0x12341234);
  Expect.equals(-0x12341234, bytes.getInt32(0));
  bytes.setInt32(1, -0x23452345);
  Expect.equals(-0x23452345, bytes.getInt32(1));
  bytes.setInt32(2, -0x12341234);
  Expect.equals(-0x12341234, bytes.getInt32(2));
  bytes.setInt32(3, -0x23452345);
  Expect.equals(-0x23452345, bytes.getInt32(3));
}

unalignedUint64() {
  var bytes = new ByteData(64);
  bytes.setUint64(0, 0xABCDABCD);
  Expect.equals(0xABCDABCD, bytes.getUint64(0));
  bytes.setUint64(1, 0xBCDEBCDE);
  Expect.equals(0xBCDEBCDE, bytes.getUint64(1));
  bytes.setUint64(2, 0xABCDABCD);
  Expect.equals(0xABCDABCD, bytes.getUint64(2));
  bytes.setUint64(3, 0xBCDEBCDE);
  Expect.equals(0xBCDEBCDE, bytes.getUint64(3));
  bytes.setUint64(4, 0xABCDABCD);
  Expect.equals(0xABCDABCD, bytes.getUint64(4));
  bytes.setUint64(5, 0xBCDEBCDE);
  Expect.equals(0xBCDEBCDE, bytes.getUint64(5));
  bytes.setUint64(6, 0xABCDABCD);
  Expect.equals(0xABCDABCD, bytes.getUint64(6));
  bytes.setUint64(7, 0xBCDEBCDE);
  Expect.equals(0xBCDEBCDE, bytes.getUint64(7));
}

unalignedInt64() {
  var bytes = new ByteData(64);
  bytes.setInt64(0, -0x12341234);
  Expect.equals(-0x12341234, bytes.getInt64(0));
  bytes.setInt64(1, -0x23452345);
  Expect.equals(-0x23452345, bytes.getInt64(1));
  bytes.setInt64(2, -0x12341234);
  Expect.equals(-0x12341234, bytes.getInt64(2));
  bytes.setInt64(3, -0x23452345);
  Expect.equals(-0x23452345, bytes.getInt64(3));
  bytes.setInt64(4, -0x12341234);
  Expect.equals(-0x12341234, bytes.getInt64(4));
  bytes.setInt64(5, -0x23452345);
  Expect.equals(-0x23452345, bytes.getInt64(5));
  bytes.setInt64(6, -0x12341234);
  Expect.equals(-0x12341234, bytes.getInt64(6));
  bytes.setInt64(7, -0x23452345);
  Expect.equals(-0x23452345, bytes.getInt64(7));
}

main() {
  for (var i = 0; i < 20; i++) {
    unalignedUint16();
    unalignedInt16();
    unalignedUint32();
    unalignedInt32();
    unalignedUint64();
    unalignedInt64();
  }
}
