// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10 --no-background_compilation

import 'dart:typed_data';
import 'package:expect/expect.dart';

unalignedUint16() {
  var bytes = new ByteData(64);
  bytes.setUint16(0, 0xABCD, Endianness.HOST_ENDIAN);
  Expect.equals(0xABCD, bytes.getUint16(0, Endianness.HOST_ENDIAN));
  bytes.setUint16(1, 0xBCDE, Endianness.HOST_ENDIAN);
  Expect.equals(0xBCDE, bytes.getUint16(1, Endianness.HOST_ENDIAN));
}

unalignedInt16() {
  var bytes = new ByteData(64);
  bytes.setInt16(0, -0x1234, Endianness.HOST_ENDIAN);
  Expect.equals(-0x1234, bytes.getInt16(0, Endianness.HOST_ENDIAN));
  bytes.setInt16(1, -0x2345, Endianness.HOST_ENDIAN);
  Expect.equals(-0x2345, bytes.getInt16(1, Endianness.HOST_ENDIAN));
}

unalignedUint32() {
  var bytes = new ByteData(64);
  bytes.setUint32(0, 0xABCDABCD, Endianness.HOST_ENDIAN);
  Expect.equals(0xABCDABCD, bytes.getUint32(0, Endianness.HOST_ENDIAN));
  bytes.setUint32(1, 0xBCDEBCDE, Endianness.HOST_ENDIAN);
  Expect.equals(0xBCDEBCDE, bytes.getUint32(1, Endianness.HOST_ENDIAN));
  bytes.setUint32(2, 0xABCDABCD, Endianness.HOST_ENDIAN);
  Expect.equals(0xABCDABCD, bytes.getUint32(2, Endianness.HOST_ENDIAN));
  bytes.setUint32(3, 0xBCDEBCDE, Endianness.HOST_ENDIAN);
  Expect.equals(0xBCDEBCDE, bytes.getUint32(3, Endianness.HOST_ENDIAN));
}

unalignedInt32() {
  var bytes = new ByteData(64);
  bytes.setInt32(0, -0x12341234, Endianness.HOST_ENDIAN);
  Expect.equals(-0x12341234, bytes.getInt32(0, Endianness.HOST_ENDIAN));
  bytes.setInt32(1, -0x23452345, Endianness.HOST_ENDIAN);
  Expect.equals(-0x23452345, bytes.getInt32(1, Endianness.HOST_ENDIAN));
  bytes.setInt32(2, -0x12341234, Endianness.HOST_ENDIAN);
  Expect.equals(-0x12341234, bytes.getInt32(2, Endianness.HOST_ENDIAN));
  bytes.setInt32(3, -0x23452345, Endianness.HOST_ENDIAN);
  Expect.equals(-0x23452345, bytes.getInt32(3, Endianness.HOST_ENDIAN));
}

unalignedUint64() {
  var bytes = new ByteData(64);
  bytes.setUint64(0, 0xABCDABCD12345678, Endianness.HOST_ENDIAN);
  Expect.equals(0xABCDABCD12345678, bytes.getUint64(0, Endianness.HOST_ENDIAN));
  bytes.setUint64(1, 0xBCDEBCDE12345678, Endianness.HOST_ENDIAN);
  Expect.equals(0xBCDEBCDE12345678, bytes.getUint64(1, Endianness.HOST_ENDIAN));
  bytes.setUint64(2, 0xABCDABCD12345678, Endianness.HOST_ENDIAN);
  Expect.equals(0xABCDABCD12345678, bytes.getUint64(2, Endianness.HOST_ENDIAN));
  bytes.setUint64(3, 0xBCDEBCDE12345678, Endianness.HOST_ENDIAN);
  Expect.equals(0xBCDEBCDE12345678, bytes.getUint64(3, Endianness.HOST_ENDIAN));
  bytes.setUint64(4, 0xABCDABCD12345678, Endianness.HOST_ENDIAN);
  Expect.equals(0xABCDABCD12345678, bytes.getUint64(4, Endianness.HOST_ENDIAN));
  bytes.setUint64(5, 0xBCDEBCDE12345678, Endianness.HOST_ENDIAN);
  Expect.equals(0xBCDEBCDE12345678, bytes.getUint64(5, Endianness.HOST_ENDIAN));
  bytes.setUint64(6, 0xABCDABCD12345678, Endianness.HOST_ENDIAN);
  Expect.equals(0xABCDABCD12345678, bytes.getUint64(6, Endianness.HOST_ENDIAN));
  bytes.setUint64(7, 0xBCDEBCDE12345678, Endianness.HOST_ENDIAN);
  Expect.equals(0xBCDEBCDE12345678, bytes.getUint64(7, Endianness.HOST_ENDIAN));
}

unalignedInt64() {
  var bytes = new ByteData(64);
  bytes.setInt64(0, -0x12341234ABCDABCD, Endianness.HOST_ENDIAN);
  Expect.equals(-0x12341234ABCDABCD, bytes.getInt64(0, Endianness.HOST_ENDIAN));
  bytes.setInt64(1, -0x23452345ABCDABCD, Endianness.HOST_ENDIAN);
  Expect.equals(-0x23452345ABCDABCD, bytes.getInt64(1, Endianness.HOST_ENDIAN));
  bytes.setInt64(2, -0x12341234ABCDABCD, Endianness.HOST_ENDIAN);
  Expect.equals(-0x12341234ABCDABCD, bytes.getInt64(2, Endianness.HOST_ENDIAN));
  bytes.setInt64(3, -0x23452345ABCDABCD, Endianness.HOST_ENDIAN);
  Expect.equals(-0x23452345ABCDABCD, bytes.getInt64(3, Endianness.HOST_ENDIAN));
  bytes.setInt64(4, -0x12341234ABCDABCD, Endianness.HOST_ENDIAN);
  Expect.equals(-0x12341234ABCDABCD, bytes.getInt64(4, Endianness.HOST_ENDIAN));
  bytes.setInt64(5, -0x23452345ABCDABCD, Endianness.HOST_ENDIAN);
  Expect.equals(-0x23452345ABCDABCD, bytes.getInt64(5, Endianness.HOST_ENDIAN));
  bytes.setInt64(6, -0x12341234ABCDABCD, Endianness.HOST_ENDIAN);
  Expect.equals(-0x12341234ABCDABCD, bytes.getInt64(6, Endianness.HOST_ENDIAN));
  bytes.setInt64(7, -0x23452345ABCDABCD, Endianness.HOST_ENDIAN);
  Expect.equals(-0x23452345ABCDABCD, bytes.getInt64(7, Endianness.HOST_ENDIAN));
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
