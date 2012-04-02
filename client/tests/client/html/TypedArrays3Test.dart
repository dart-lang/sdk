// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('TypedArrays2Test');
#import('../../../../lib/unittest/unittest_html.dart');
#import('dart:html');

main() {

  forLayoutTests();

  test('setElementsTest_dynamic', () {
      var a1 = new Int8Array(1024);

      a1.setElements([0x50,0x60,0x70], 4);

      var a2 = new Uint32Array.fromBuffer(a1.buffer);
      Expect.equals(0x00000000, a2[0]);
      Expect.equals(0x00706050, a2[1]);

      a2.setElements([0x01020304], 2);
      Expect.equals(0x04, a1[8]);
      Expect.equals(0x01, a1[11]);
  });

  test('setElementsTest_typed', () {
      Int8Array a1 = new Int8Array(1024);

      a1.setElements([0x50,0x60,0x70], 4);

      Uint32Array a2 = new Uint32Array.fromBuffer(a1.buffer);
      Expect.equals(0x00000000, a2[0]);
      Expect.equals(0x00706050, a2[1]);

      a2.setElements([0x01020304], 2);
      Expect.equals(0x04, a1[8]);
      Expect.equals(0x01, a1[11]);
  });
}
