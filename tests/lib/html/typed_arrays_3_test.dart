// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:typed_data';

import 'package:expect/minitest.dart';

main() {
  // Only perform tests if ArrayBuffer is supported.
  if (!Platform.supportsTypedData) {
    return;
  }

  test('setElementsTest_dynamic', () {
    var a1 = new Int8List(1024);

    a1.setRange(4, 7, [0x50, 0x60, 0x70]);

    var a2 = new Uint32List.view(a1.buffer);
    expect(a2[0], 0x00000000);
    expect(a2[1], 0x00706050);

    a2.setRange(2, 3, [0x01020304]);
    expect(a1[8], 0x04);
    expect(a1[11], 0x01);
  });

  test('setElementsTest_typed', () {
    Int8List a1 = new Int8List(1024);

    a1.setRange(4, 7, [0x50, 0x60, 0x70]);

    Uint32List a2 = new Uint32List.view(a1.buffer);
    expect(a2[0], 0x00000000);
    expect(a2[1], 0x00706050);

    a2.setRange(2, 3, [0x01020304]);
    expect(a1[8], 0x04);
    expect(a1[11], 0x01);
  });
}
