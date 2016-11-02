// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10 --no-background_compilation

import 'dart:typed_data';
import 'package:expect/expect.dart';

unalignedUint16() {
  var bytes = new ByteData(64);
  for (var i = 0; i < 2; i++) {
    bytes.setUint16(i, 0xABCD);
    Expect.equals(0xABCD, bytes.getUint16(i));
  }
}

unalignedInt16() {
  var bytes = new ByteData(64);
  for (var i = 0; i < 2; i++) {
    bytes.setInt16(i, -0x1234);
    Expect.equals(-0x1234, bytes.getInt16(i));
  }
}

unalignedUint32() {
  var bytes = new ByteData(64);
  for (var i = 0; i < 4; i++) {
    bytes.setUint32(i, 0xABCDABCD);
    Expect.equals(0xABCDABCD, bytes.getUint32(i));
  }
}

unalignedInt32() {
  var bytes = new ByteData(64);
  for (var i = 0; i < 4; i++) {
    bytes.setInt32(i, -0x12341234);
    Expect.equals(-0x12341234, bytes.getInt32(i));
  }
}

unalignedUint64() {
  var bytes = new ByteData(64);
  for (var i = 0; i < 8; i++) {
    bytes.setUint64(i, 0xABCDABCD);
    Expect.equals(0xABCDABCD, bytes.getUint64(i));
  }
}

unalignedInt64() {
  var bytes = new ByteData(64);
  for (var i = 0; i < 8; i++) {
    bytes.setInt64(i, -0x12341234);
    Expect.equals(-0x12341234, bytes.getInt64(i));
  }
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
