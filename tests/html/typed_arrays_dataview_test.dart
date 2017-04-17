// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library typed_arrays_dataview_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';
import 'dart:typed_data';

main() {
  useHtmlConfiguration();

  // Only perform tests if ArrayBuffer is supported.
  if (!Platform.supportsTypedData) {
    return;
  }

  test('create', () {
    var bd = new ByteData(100);
    expect(bd.lengthInBytes, 100);
    expect(bd.offsetInBytes, 0);

    var a1 = new Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

    var bd2 = new ByteData.view(a1.buffer);
    expect(bd2.lengthInBytes, 8);
    expect(bd2.offsetInBytes, 0);

    var bd3 = new ByteData.view(a1.buffer, 2);
    expect(bd3.lengthInBytes, 6);
    expect(bd3.offsetInBytes, 2);

    var bd4 = new ByteData.view(a1.buffer, 3, 4);
    expect(bd4.lengthInBytes, 4);
    expect(bd4.offsetInBytes, 3);
  });

  test('access8', () {
    var a1 = new Uint8List.fromList([0, 0, 3, 255, 0, 0, 0, 0, 0, 0]);

    var bd = new ByteData.view(a1.buffer, 2, 6);

    expect(bd.getInt8(0), equals(3));
    expect(bd.getInt8(1), equals(-1));
    expect(bd.getUint8(0), equals(3));
    expect(bd.getUint8(1), equals(255));

    bd.setInt8(2, -56);
    expect(bd.getInt8(2), equals(-56));
    expect(bd.getUint8(2), equals(200));

    bd.setUint8(3, 200);
    expect(bd.getInt8(3), equals(-56));
    expect(bd.getUint8(3), equals(200));
  });

  test('access16', () {
    var a1 = new Uint8List.fromList([0, 0, 3, 255, 0, 0, 0, 0, 0, 0]);

    var bd = new ByteData.view(a1.buffer, 2);

    expect(bd.lengthInBytes, equals(10 - 2));

    expect(bd.getInt16(0), equals(1023));
    expect(bd.getInt16(0, Endianness.BIG_ENDIAN), equals(1023));
    expect(bd.getInt16(0, Endianness.LITTLE_ENDIAN), equals(-253));

    expect(bd.getUint16(0), equals(1023));
    expect(bd.getUint16(0, Endianness.BIG_ENDIAN), equals(1023));
    expect(bd.getUint16(0, Endianness.LITTLE_ENDIAN), equals(0xFF03));

    bd.setInt16(2, -1);
    expect(bd.getInt16(2), equals(-1));
    expect(bd.getUint16(2), equals(0xFFFF));
  });

  test('access32', () {
    var a1 = new Uint8List.fromList([0, 0, 3, 255, 0, 0, 0, 0, 0, 0]);

    var bd = new ByteData.view(a1.buffer);

    expect(bd.getInt32(0), equals(1023));
    expect(bd.getInt32(0, Endianness.BIG_ENDIAN), equals(1023));
    expect(bd.getInt32(0, Endianness.LITTLE_ENDIAN), equals(-0xFD0000));

    expect(bd.getUint32(0), equals(1023));
    expect(bd.getUint32(0, Endianness.BIG_ENDIAN), equals(1023));
    expect(bd.getUint32(0, Endianness.LITTLE_ENDIAN), equals(0xFF030000));
  });
}
