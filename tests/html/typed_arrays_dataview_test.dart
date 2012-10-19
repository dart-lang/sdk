// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('typed_arrays_dataview_test');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  test('access8', () {
      var a1 = new Uint8Array.fromList([0,0,3,255,0,0,0,0,0,0]);

      var dv = new DataView(a1.buffer, 2, 6);

      expect(dv.getInt8(0), equals(3));
      expect(dv.getInt8(1), equals(-1));
      expect(dv.getUint8(0), equals(3));
      expect(dv.getUint8(1), equals(255));

      dv.setInt8(2, -56);
      expect(dv.getInt8(2), equals(-56));
      expect(dv.getUint8(2), equals(200));

      dv.setUint8(3, 200);
      expect(dv.getInt8(3), equals(-56));
      expect(dv.getUint8(3), equals(200));
  });

  test('access16', () {
      var a1 = new Uint8Array.fromList([0,0,3,255,0,0,0,0,0,0]);

      var dv = new DataView(a1.buffer, 2);

      expect(dv.byteLength, equals(10 - 2));

      expect(dv.getInt16(0), equals(1023));
      expect(dv.getInt16(0, false), equals(1023));
      // OPTIONALS expect(dv.getInt16(0, littleEndian: false), equals(1023));
      expect(dv.getInt16(0, false), equals(1023));
      expect(dv.getInt16(0, true), equals(-253));
      // OPTIONALS expect(dv.getInt16(0, littleEndian: true), equals(-253));
      expect(dv.getInt16(0, true), equals(-253));

      expect(dv.getUint16(0), equals(1023));
      // OPTIONALS expect(dv.getUint16(0, littleEndian: false), equals(1023));
      expect(dv.getUint16(0, false), equals(1023));
      // OPTIONALS expect(dv.getUint16(0, littleEndian: true), equals(0xFF03));
      expect(dv.getUint16(0, true), equals(0xFF03));

      dv.setInt16(2, -1);
      expect(dv.getInt16(2), equals(-1));
      expect(dv.getUint16(2), equals(0xFFFF));
  });

  test('access32', () {
      var a1 = new Uint8Array.fromList([0,0,3,255,0,0,0,0,0,0]);

      var dv = new DataView(a1.buffer);

      expect(dv.getInt32(0), equals(1023));
      expect(dv.getInt32(0, false), equals(1023));
      // OPTIONALS expect(dv.getInt32(0, littleEndian: false), equals(1023));
      expect(dv.getInt32(0, false), equals(1023));
      expect(dv.getInt32(0, true), equals(-0xFD0000));
      // OPTIONALS expect(dv.getInt32(0, littleEndian: true), equals(-0xFD0000));
      expect(dv.getInt32(0, true), equals(-0xFD0000));

      expect(dv.getUint32(0), equals(1023));
      // OPTIONALS expect(dv.getUint32(0, littleEndian: false), equals(1023));
      expect(dv.getUint32(0, false), equals(1023));
      // OPTIONALS expect(dv.getUint32(0, littleEndian: true), equals(0xFF030000));
      expect(dv.getUint32(0, true), equals(0xFF030000));
  });

}
