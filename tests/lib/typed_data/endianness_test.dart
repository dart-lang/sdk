// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import "package:expect/expect.dart";

main() {
  swapTest();
  swapTestVar(Endian.little, Endian.big);
  swapTestVar(Endian.big, Endian.little);
}

swapTest() {
  ByteData data = new ByteData(16);
  Expect.equals(16, data.lengthInBytes);
  for (int i = 0; i < 4; i++) {
    data.setInt32(i * 4, i);
  }

  for (int i = 0; i < data.lengthInBytes; i += 4) {
    var e = data.getInt32(i, Endian.big);
    data.setInt32(i, e, Endian.little);
  }

  Expect.equals(0x02000000, data.getInt32(8));

  for (int i = 0; i < data.lengthInBytes; i += 2) {
    var e = data.getInt16(i, Endian.big);
    data.setInt16(i, e, Endian.little);
  }

  Expect.equals(0x00020000, data.getInt32(8));

  for (int i = 0; i < data.lengthInBytes; i += 4) {
    var e = data.getUint32(i, Endian.little);
    data.setUint32(i, e, Endian.big);
  }

  Expect.equals(0x00000200, data.getInt32(8));

  for (int i = 0; i < data.lengthInBytes; i += 2) {
    var e = data.getUint16(i, Endian.little);
    data.setUint16(i, e, Endian.big);
  }

  Expect.equals(0x00000002, data.getInt32(8));
}

swapTestVar(read, write) {
  ByteData data = new ByteData(16);
  Expect.equals(16, data.lengthInBytes);
  for (int i = 0; i < 4; i++) {
    data.setInt32(i * 4, i);
  }

  for (int i = 0; i < data.lengthInBytes; i += 4) {
    var e = data.getInt32(i, read);
    data.setInt32(i, e, write);
  }

  Expect.equals(0x02000000, data.getInt32(8));

  for (int i = 0; i < data.lengthInBytes; i += 2) {
    var e = data.getInt16(i, read);
    data.setInt16(i, e, write);
  }

  Expect.equals(0x00020000, data.getInt32(8));

  for (int i = 0; i < data.lengthInBytes; i += 4) {
    var e = data.getUint32(i, read);
    data.setUint32(i, e, write);
  }

  Expect.equals(0x00000200, data.getInt32(8));

  for (int i = 0; i < data.lengthInBytes; i += 2) {
    var e = data.getUint16(i, read);
    data.setUint16(i, e, write);
  }

  Expect.equals(0x00000002, data.getInt32(8));
}
