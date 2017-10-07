// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing typed data.

// Library tag to be able to run in html test framework.
library TypedDataTest;

import "package:expect/expect.dart";
import 'dart:typed_data';

validate(List list, num expected) {
  for (int i = 0; i < list.length; i++) {
    Expect.equals(expected, list[i]);
  }
}

testView() {
  var list = new Int8List(128);
  for (var i = 0; i < list.length; i++) {
    list[i] = 42;
  }
  var ba = list.buffer;

  var slist = new Int16List.view(ba, 0, 32);
  validate(slist, 10794);
  var uslist = new Uint16List.view(ba, 0, 32);
  validate(uslist, 10794);

  var ilist = new Int32List.view(ba, 0, 16);
  validate(ilist, 707406378);
  var uilist = new Uint32List.view(ba, 0, 16);
  validate(uilist, 707406378);

  var llist = new Int64List.view(ba, 0, 8);
  validate(llist, 3038287259199220266);
  var ullist = new Uint64List.view(ba, 0, 8);
  validate(ullist, 3038287259199220266);

  var flist = new Float32List.view(ba, 0, 16);
  validate(flist, 1.511366173271439e-13);
  var dlist = new Float64List.view(ba, 0, 8);
  validate(dlist, 1.4260258159703532e-105);
}

testSetters() {
  var blist = new ByteData(128);
  blist.setInt8(0, 0xffff);
  Expect.equals(-1, blist.getInt8(0));
  blist.setUint8(0, 0xffff);
  Expect.equals(0xff, blist.getUint8(0));
  blist.setInt16(0, 0xffffffff);
  Expect.equals(-1, blist.getInt16(0, Endianness.LITTLE_ENDIAN));
  blist.setUint16(0, 0xffffffff, Endianness.LITTLE_ENDIAN);
  Expect.equals(0xffff, blist.getUint16(0, Endianness.LITTLE_ENDIAN));
  blist.setInt32(0, 0xffffffffffff, Endianness.LITTLE_ENDIAN);
  Expect.equals(-1, blist.getInt32(0, Endianness.LITTLE_ENDIAN));
  blist.setUint32(0, 0xffffffffffff, Endianness.LITTLE_ENDIAN);
  Expect.equals(0xffffffff, blist.getUint32(0, Endianness.LITTLE_ENDIAN));
  blist.setInt64(0, 0xffffffffffffffffff, Endianness.LITTLE_ENDIAN);
  Expect.equals(-1, blist.getInt64(0, Endianness.LITTLE_ENDIAN));
  blist.setUint64(0, 0xffffffffffffffffff, Endianness.LITTLE_ENDIAN);
  Expect.equals(
      0xffffffffffffffff, blist.getUint64(0, Endianness.LITTLE_ENDIAN));
  blist.setInt32(0, 18446744073709551614, Endianness.LITTLE_ENDIAN);
  Expect.equals(-2, blist.getInt32(0, Endianness.LITTLE_ENDIAN));
  blist.setUint32(0, 18446744073709551614, Endianness.LITTLE_ENDIAN);
  Expect.equals(0xfffffffe, blist.getUint32(0, Endianness.LITTLE_ENDIAN));
  blist.setInt64(0, 18446744073709551614, Endianness.LITTLE_ENDIAN);
  Expect.equals(-2, blist.getInt64(0, Endianness.LITTLE_ENDIAN));
  blist.setUint64(0, 18446744073709551614, Endianness.LITTLE_ENDIAN);
  Expect.equals(
      0xfffffffffffffffe, blist.getUint64(0, Endianness.LITTLE_ENDIAN));

  blist.setFloat32(0, 18446744073709551614.0, Endianness.LITTLE_ENDIAN);
  Expect.equals(
      18446744073709551614.0, blist.getFloat32(0, Endianness.LITTLE_ENDIAN));
  blist.setFloat64(0, 18446744073709551614.0, Endianness.LITTLE_ENDIAN);
  Expect.equals(
      18446744073709551614.0, blist.getFloat64(0, Endianness.LITTLE_ENDIAN));
}

main() {
  testView();
  testSetters();
}
