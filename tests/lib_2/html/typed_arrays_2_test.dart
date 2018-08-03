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

  test('viewTest_dynamic', () {
    var a1 = new Uint8List(1024);
    for (int i = 0; i < a1.length; i++) {
      a1[i] = i; // 0,1,2,...,254,255,0,1,2,...
    }

    var a2 = new Uint32List.view(a1.buffer);
    expect(1024 ~/ 4, a2.length);
    expect(a2[0], 0x03020100);
    expect(a2[1], 0x07060504);
    expect(a2[2], 0x0B0A0908);
    expect(a2[50], 0xCBCAC9C8);
    expect(a2[51], 0xCFCECDCC);
    expect(a2[64], 0x03020100);

    a2 = new Uint32List.view(a1.buffer, 200);
    expect(a2.length, (1024 - 200) ~/ 4);
    expect(a2[0], 0xCBCAC9C8);
    expect(a2[1], 0xCFCECDCC);
    expect(a2[14], 0x03020100);

    a2 = new Uint32List.view(a1.buffer, 456, 20);
    expect(a2.length, 20);
    expect(a2[0], 0xCBCAC9C8);
    expect(a2[1], 0xCFCECDCC);
    expect(a2[14], 0x03020100);

    // OPTIONALS a2 = new Uint32List.view(a1.buffer, length: 30, byteOffset: 456);
    a2 = new Uint32List.view(a1.buffer, 456, 30);
    expect(a2.length, 30);
    expect(a2[0], 0xCBCAC9C8);
    expect(a2[1], 0xCFCECDCC);
    expect(a2[14], 0x03020100);
  });

  test('viewTest_typed', () {
    Uint8List a1 = new Uint8List(1024);
    for (int i = 0; i < a1.length; i++) {
      a1[i] = i;
    }

    Uint32List a2 = new Uint32List.view(a1.buffer);
    expect(a2.length, 1024 ~/ 4);
    expect(a2[0], 0x03020100);
    expect(a2[50], 0xCBCAC9C8);
    expect(a2[51], 0xCFCECDCC);
    expect(a2[64], 0x03020100);

    a2 = new Uint32List.view(a1.buffer, 200);
    expect(a2.length, (1024 - 200) ~/ 4);
    expect(a2[0], 0xCBCAC9C8);
    expect(a2[1], 0xCFCECDCC);
    expect(a2[14], 0x03020100);

    a2 = new Uint32List.view(a1.buffer, 456, 20);
    expect(20, a2.length);
    expect(a2[0], 0xCBCAC9C8);
    expect(a2[1], 0xCFCECDCC);
    expect(a2[14], 0x03020100);

    // OPTIONALS a2 = new Uint32List.view(a1.buffer, length: 30, byteOffset: 456);
    a2 = new Uint32List.view(a1.buffer, 456, 30);
    expect(a2.length, 30);
    expect(a2[0], 0xCBCAC9C8);
    expect(a2[1], 0xCFCECDCC);
    expect(a2[14], 0x03020100);
  });
}
