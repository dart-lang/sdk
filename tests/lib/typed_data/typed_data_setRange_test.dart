// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'dart:typed_data';


initialize(a) {
  for (int i = 0; i < a.length; i++) {
    a[i] = i + 1;
  }
}

makeInt16View(buffer, byteOffset, length) =>
    new Int16List.view(buffer, byteOffset, length);

makeUint16View(buffer, byteOffset, length) =>
    new Uint16List.view(buffer, byteOffset, length);


sameTypeTest() {
  checkSameSize(new Int16List(9), makeInt16View, makeInt16View);
  checkSameSize(new Uint16List(9), makeUint16View, makeUint16View);
}

sameElementSizeTest() {
  checkSameSize(new Int16List(9), makeInt16View, makeUint16View);
  checkSameSize(new Int16List(9), makeUint16View, makeInt16View);
}

checkSameSize(a0, constructor1, constructor2) {
  // Typed lists a1 and a2 share a buffer as follows (bytes):
  //
  //  a0:  aabbccddeeffgghhii
  //  a1:  aabbccddeeffgg
  //  a2:      aabbccddeeffgg

  var buffer = a0.buffer;
  var a1 = constructor1(buffer, 0, 7);
  var a2 = constructor2(buffer, 2 * 2, 7);

  initialize(a0);
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9]', '$a0');
  Expect.equals('[1, 2, 3, 4, 5, 6, 7]', '$a1');
  Expect.equals('[3, 4, 5, 6, 7, 8, 9]', '$a2');

  initialize(a0);
  a1.setRange(0, 7, a2);
  Expect.equals('[3, 4, 5, 6, 7, 8, 9, 8, 9]', '$a0');

  initialize(a0);
  a2.setRange(0, 7, a1);
  Expect.equals('[1, 2, 1, 2, 3, 4, 5, 6, 7]', '$a0');

  initialize(a0);
  a1.setRange(1, 7, a2);
  Expect.equals('[1, 3, 4, 5, 6, 7, 8, 8, 9]', '$a0');

  initialize(a0);
  a2.setRange(1, 7, a1);
  Expect.equals('[1, 2, 3, 1, 2, 3, 4, 5, 6]', '$a0');

  initialize(a0);
  a1.setRange(0, 6, a2, 1);
  Expect.equals('[4, 5, 6, 7, 8, 9, 7, 8, 9]', '$a0');

  initialize(a0);
  a2.setRange(0, 6, a1, 1);
  Expect.equals('[1, 2, 2, 3, 4, 5, 6, 7, 9]', '$a0');
}

expandContractTest() {
  // Copying between views that have different element sizes can't be done with
  // a single scan-up or scan-down.
  //
  // Typed lists a1 and a2 share a buffer as follows:
  //
  // a1:  aaaabbbbccccddddeeeeffffgggghhhh
  // a2:              abcdefgh

  var a1 = new Int32List(8);
  var buffer = a1.buffer;
  var a2 = new Int8List.view(buffer, 12, 8);

  initialize(a2);
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', '$a2');
  a1.setRange(0, 8, a2);
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', '$a1');

  initialize(a1);
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', '$a1');
  a2.setRange(0, 8, a1);
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', '$a2');
}

main() {
  sameTypeTest();
  sameElementSizeTest();
  expandContractTest();
}
