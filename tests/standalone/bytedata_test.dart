// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing typed data.

// Library tag to be able to run in html test framework.
library ByteDataTest;

import "package:expect/expect.dart";
import 'dart:typed_data';

testGetters() {
  bool host_is_little_endian =
      (new Uint8List.view(new Uint16List.fromList([1]).buffer))[0] == 1;

  var list = new Uint8List(8);
  list[0] = 0xf1;
  list[1] = 0xf2;
  list[2] = 0xf3;
  list[3] = 0xf4;
  list[4] = 0xf5;
  list[5] = 0xf6;
  list[6] = 0xf7;
  list[7] = 0xf8;
  var ba = list.buffer;

  ByteData bd = new ByteData.view(ba);
  var value;
  int expected_value_be = -3598;
  int expected_value_le = -3343;

  value = bd.getInt16(0); // Default is big endian access.
  Expect.equals(expected_value_be, value);
  value = bd.getInt16(0, Endianness.BIG_ENDIAN);
  Expect.equals(expected_value_be, value);
  value = bd.getInt16(0, Endianness.LITTLE_ENDIAN);
  Expect.equals(expected_value_le, value);
  value = bd.getInt16(0, Endianness.HOST_ENDIAN);
  if (host_is_little_endian) {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.LITTLE_ENDIAN));
    Expect.equals(expected_value_le, value);
  } else {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.BIG_ENDIAN));
    Expect.equals(expected_value_be, value);
  }

  value = bd.getUint16(0); // Default is big endian access.
  Expect.equals(0xf1f2, value);
  value = bd.getUint16(0, Endianness.BIG_ENDIAN);
  Expect.equals(0xf1f2, value);
  value = bd.getUint16(0, Endianness.LITTLE_ENDIAN);
  Expect.equals(0xf2f1, value);
  if (host_is_little_endian) {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.LITTLE_ENDIAN));
    Expect.equals(0xf2f1, value);
  } else {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.BIG_ENDIAN));
    Expect.equals(0xf1f2, value);
  }

  expected_value_be = -235736076;
  expected_value_le = -185339151;

  value = bd.getInt32(0); // Default is big endian access.
  Expect.equals(expected_value_be, value);
  value = bd.getInt32(0, Endianness.BIG_ENDIAN);
  Expect.equals(expected_value_be, value);
  value = bd.getInt32(0, Endianness.LITTLE_ENDIAN);
  Expect.equals(expected_value_le, value);
  if (host_is_little_endian) {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.LITTLE_ENDIAN));
    Expect.equals(expected_value_le, value);
  } else {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.BIG_ENDIAN));
    Expect.equals(expected_value_be, value);
  }

  value = bd.getUint32(0); // Default is big endian access.
  Expect.equals(0xf1f2f3f4, value);
  value = bd.getUint32(0, Endianness.BIG_ENDIAN);
  Expect.equals(0xf1f2f3f4, value);
  value = bd.getUint32(0, Endianness.LITTLE_ENDIAN);
  Expect.equals(0xf4f3f2f1, value);
  if (host_is_little_endian) {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.LITTLE_ENDIAN));
    Expect.equals(0xf4f3f2f1, value);
  } else {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.BIG_ENDIAN));
    Expect.equals(0xf1f2f3f4, value);
  }

  expected_value_be = -1012478732780767240;
  expected_value_le = -506664896818842895;

  value = bd.getInt64(0); // Default is big endian access.
  Expect.equals(expected_value_be, value);
  value = bd.getInt64(0, Endianness.BIG_ENDIAN);
  Expect.equals(expected_value_be, value);
  value = bd.getInt64(0, Endianness.LITTLE_ENDIAN);
  Expect.equals(expected_value_le, value);
  if (host_is_little_endian) {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.LITTLE_ENDIAN));
    Expect.equals(expected_value_le, value);
  } else {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.BIG_ENDIAN));
    Expect.equals(expected_value_be, value);
  }

  value = bd.getUint64(0); // Default is big endian access.
  Expect.equals(0xf1f2f3f4f5f6f7f8, value);
  value = bd.getUint64(0, Endianness.BIG_ENDIAN);
  Expect.equals(0xf1f2f3f4f5f6f7f8, value);
  value = bd.getUint64(0, Endianness.LITTLE_ENDIAN);
  Expect.equals(0xf8f7f6f5f4f3f2f1, value);
  if (host_is_little_endian) {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.LITTLE_ENDIAN));
    Expect.equals(0xf8f7f6f5f4f3f2f1, value);
  } else {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.BIG_ENDIAN));
    Expect.equals(0xf1f2f3f4f5f6f7f8, value);
  }

  double expected_be_value = -2.4060893954673178e+30;
  double expected_le_value = -1.5462104171572421e+32;
  value = bd.getFloat32(0); // Default is big endian access.
  Expect.equals(expected_be_value, value);
  value = bd.getFloat32(0, Endianness.BIG_ENDIAN);
  Expect.equals(expected_be_value, value);
  value = bd.getFloat32(0, Endianness.LITTLE_ENDIAN);
  Expect.equals(expected_le_value, value);
  if (host_is_little_endian) {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.LITTLE_ENDIAN));
    Expect.equals(expected_le_value, value);
  } else {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.BIG_ENDIAN));
    Expect.equals(expected_be_value, value);
  }

  expected_be_value = -7.898661740976602e+240;
  expected_le_value = -5.185705956736366e+274;
  value = bd.getFloat64(0); // Default is big endian access.
  Expect.equals(expected_be_value, value);
  value = bd.getFloat64(0, Endianness.BIG_ENDIAN);
  Expect.equals(expected_be_value, value);
  value = bd.getFloat64(0, Endianness.LITTLE_ENDIAN);
  Expect.equals(expected_le_value, value);
  if (host_is_little_endian) {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.LITTLE_ENDIAN));
    Expect.equals(expected_le_value, value);
  } else {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.BIG_ENDIAN));
    Expect.equals(expected_be_value, value);
  }
}

validate16be(var list) {
  Expect.equals(0xf1, list[0]);
  Expect.equals(0xf2, list[1]);
}

validate16le(var list) {
  Expect.equals(0xf2, list[0]);
  Expect.equals(0xf1, list[1]);
}

validate32be(var list) {
  Expect.equals(0xf1, list[0]);
  Expect.equals(0xf2, list[1]);
  Expect.equals(0xf3, list[2]);
  Expect.equals(0xf4, list[3]);
}

validate32le(var list) {
  Expect.equals(0xf4, list[0]);
  Expect.equals(0xf3, list[1]);
  Expect.equals(0xf2, list[2]);
  Expect.equals(0xf1, list[3]);
}

validate64be(var list) {
  Expect.equals(0xf1, list[0]);
  Expect.equals(0xf2, list[1]);
  Expect.equals(0xf3, list[2]);
  Expect.equals(0xf4, list[3]);
  Expect.equals(0xf5, list[4]);
  Expect.equals(0xf6, list[5]);
  Expect.equals(0xf7, list[6]);
  Expect.equals(0xf8, list[7]);
}

validate64le(var list) {
  Expect.equals(0xf8, list[0]);
  Expect.equals(0xf7, list[1]);
  Expect.equals(0xf6, list[2]);
  Expect.equals(0xf5, list[3]);
  Expect.equals(0xf4, list[4]);
  Expect.equals(0xf3, list[5]);
  Expect.equals(0xf2, list[6]);
  Expect.equals(0xf1, list[7]);
}

testSetters() {
  bool host_is_little_endian =
      (new Uint8List.view(new Uint16List.fromList([1]).buffer))[0] == 1;

  var list = new Uint8List(8);
  for (int i = 0; i < list.length; i++) {
    list[i] = 0;
  }
  var ba = list.buffer;
  ByteData bd = new ByteData.view(ba);

  bd.setInt16(0, 0xf1f2); // Default is big endian access.
  validate16be(list);
  bd.setInt16(0, 0xf1f2, Endianness.BIG_ENDIAN);
  validate16be(list);
  bd.setInt16(0, 0xf1f2, Endianness.LITTLE_ENDIAN);
  validate16le(list);
  bd.setInt16(0, 0xf1f2, Endianness.HOST_ENDIAN);
  if (host_is_little_endian) {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.LITTLE_ENDIAN));
    validate16le(list);
  } else {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.BIG_ENDIAN));
    validate16be(list);
  }

  bd.setUint16(0, 0xf1f2); // Default is big endian access.
  validate16be(list);
  bd.setUint16(0, 0xf1f2, Endianness.BIG_ENDIAN);
  validate16be(list);
  bd.setUint16(0, 0xf1f2, Endianness.LITTLE_ENDIAN);
  validate16le(list);
  bd.setUint16(0, 0xf1f2, Endianness.HOST_ENDIAN);
  if (host_is_little_endian) {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.LITTLE_ENDIAN));
    validate16le(list);
  } else {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.BIG_ENDIAN));
    validate16be(list);
  }

  bd.setInt32(0, 0xf1f2f3f4); // Default is big endian access.
  validate32be(list);
  bd.setInt32(0, 0xf1f2f3f4, Endianness.BIG_ENDIAN);
  validate32be(list);
  bd.setInt32(0, 0xf1f2f3f4, Endianness.LITTLE_ENDIAN);
  validate32le(list);
  bd.setInt32(0, 0xf1f2f3f4, Endianness.HOST_ENDIAN);
  if (host_is_little_endian) {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.LITTLE_ENDIAN));
    validate32le(list);
  } else {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.BIG_ENDIAN));
    validate32be(list);
  }

  bd.setUint32(0, 0xf1f2f3f4); // Default is big endian access.
  validate32be(list);
  bd.setUint32(0, 0xf1f2f3f4, Endianness.BIG_ENDIAN);
  validate32be(list);
  bd.setUint32(0, 0xf1f2f3f4, Endianness.LITTLE_ENDIAN);
  validate32le(list);
  bd.setUint32(0, 0xf1f2f3f4, Endianness.HOST_ENDIAN);
  if (host_is_little_endian) {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.LITTLE_ENDIAN));
    validate32le(list);
  } else {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.BIG_ENDIAN));
    validate32be(list);
  }

  bd.setInt64(0, 0xf1f2f3f4f5f6f7f8); // Default is big endian access.
  validate64be(list);
  bd.setInt64(0, 0xf1f2f3f4f5f6f7f8, Endianness.BIG_ENDIAN);
  validate64be(list);
  bd.setInt64(0, 0xf1f2f3f4f5f6f7f8, Endianness.LITTLE_ENDIAN);
  validate64le(list);
  bd.setInt64(0, 0xf1f2f3f4f5f6f7f8, Endianness.HOST_ENDIAN);
  if (host_is_little_endian) {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.LITTLE_ENDIAN));
    validate64le(list);
  } else {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.BIG_ENDIAN));
    validate64be(list);
  }

  bd.setUint64(0, 0xf1f2f3f4f5f6f7f8); // Default is big endian access.
  validate64be(list);
  bd.setUint64(0, 0xf1f2f3f4f5f6f7f8, Endianness.BIG_ENDIAN);
  validate64be(list);
  bd.setUint64(0, 0xf1f2f3f4f5f6f7f8, Endianness.LITTLE_ENDIAN);
  validate64le(list);
  bd.setUint64(0, 0xf1f2f3f4f5f6f7f8, Endianness.HOST_ENDIAN);
  if (host_is_little_endian) {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.LITTLE_ENDIAN));
    validate64le(list);
  } else {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.BIG_ENDIAN));
    validate64be(list);
  }

  bd.setFloat32(0, -2.4060893954673178e+30); // Default is big endian access.
  validate32be(list);
  bd.setFloat32(0, -2.4060893954673178e+30, Endianness.BIG_ENDIAN);
  validate32be(list);
  bd.setFloat32(0, -2.4060893954673178e+30, Endianness.LITTLE_ENDIAN);
  validate32le(list);
  bd.setFloat32(0, -2.4060893954673178e+30, Endianness.HOST_ENDIAN);
  if (host_is_little_endian) {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.LITTLE_ENDIAN));
    validate32le(list);
  } else {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.BIG_ENDIAN));
    validate32be(list);
  }

  bd.setFloat64(0, -7.898661740976602e+240); // Default is big endian access.
  validate64be(list);
  bd.setFloat64(0, -7.898661740976602e+240, Endianness.BIG_ENDIAN);
  validate64be(list);
  bd.setFloat64(0, -7.898661740976602e+240, Endianness.LITTLE_ENDIAN);
  validate64le(list);
  bd.setFloat64(0, -7.898661740976602e+240, Endianness.HOST_ENDIAN);
  if (host_is_little_endian) {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.LITTLE_ENDIAN));
    validate64le(list);
  } else {
    Expect.isTrue(identical(Endianness.HOST_ENDIAN, Endianness.BIG_ENDIAN));
    validate64be(list);
  }
}

main() {
  testGetters();
  testSetters();
}
