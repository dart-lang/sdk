// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('TypedArrays2Test');
#import('../../../../lib/unittest/unittest_html.dart');
#import('dart:html');

main() {

  forLayoutTests();

  test('fromBufferTest_var', () {
      var a1 = new Uint8Array(1024);
      for (int i = 0; i < a1.length; i++) {
        a1[i] = i; // 0,1,2,...,254,255,0,1,2,...
      }

      var a2 = new Uint32Array.fromBuffer(a1.buffer);
      Expect.equals(1024 ~/ 4, a2.length);
      Expect.equals(0x03020100, a2[0]);
      Expect.equals(0x07060504, a2[1]);
      Expect.equals(0x0B0A0908, a2[2]);
      Expect.equals(0xCBCAC9C8, a2[50]);
      Expect.equals(0xCFCECDCC, a2[51]);
      Expect.equals(0x03020100, a2[64]);

      a2 = new Uint32Array.fromBuffer(a1.buffer, 200);
      Expect.equals((1024 - 200) ~/ 4, a2.length);
      Expect.equals(0xCBCAC9C8, a2[0]);
      Expect.equals(0xCFCECDCC, a2[1]);
      Expect.equals(0x03020100, a2[14]);

      a2 = new Uint32Array.fromBuffer(a1.buffer, 456, 20);
      Expect.equals(20, a2.length);
      Expect.equals(0xCBCAC9C8, a2[0]);
      Expect.equals(0xCFCECDCC, a2[1]);
      Expect.equals(0x03020100, a2[14]);

      a2 = new Uint32Array.fromBuffer(a1.buffer, length: 30, byteOffset: 456);
      Expect.equals(30, a2.length);
      Expect.equals(0xCBCAC9C8, a2[0]);
      Expect.equals(0xCFCECDCC, a2[1]);
      Expect.equals(0x03020100, a2[14]);
  });

  test('fromBufferTest_typed', () {
      Uint8Array a1 = new Uint8Array(1024);
      for (int i = 0; i < a1.length; i++) {
        a1[i] = i;
      }

      Uint32Array a2 = new Uint32Array.fromBuffer(a1.buffer);
      Expect.equals(1024 ~/ 4, a2.length);
      Expect.equals(0x03020100, a2[0]);
      Expect.equals(0xCBCAC9C8, a2[50]);
      Expect.equals(0xCFCECDCC, a2[51]);
      Expect.equals(0x03020100, a2[64]);

      a2 = new Uint32Array.fromBuffer(a1.buffer, 200);
      Expect.equals((1024 - 200) ~/ 4, a2.length);
      Expect.equals(0xCBCAC9C8, a2[0]);
      Expect.equals(0xCFCECDCC, a2[1]);
      Expect.equals(0x03020100, a2[14]);

      a2 = new Uint32Array.fromBuffer(a1.buffer, 456, 20);
      Expect.equals(20, a2.length);
      Expect.equals(0xCBCAC9C8, a2[0]);
      Expect.equals(0xCFCECDCC, a2[1]);
      Expect.equals(0x03020100, a2[14]);

      a2 = new Uint32Array.fromBuffer(a1.buffer, length: 30, byteOffset: 456);
      Expect.equals(30, a2.length);
      Expect.equals(0xCBCAC9C8, a2[0]);
      Expect.equals(0xCFCECDCC, a2[1]);
      Expect.equals(0x03020100, a2[14]);
  });
}
