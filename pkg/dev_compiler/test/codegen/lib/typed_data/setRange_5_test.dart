// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';
import 'setRange_lib.dart';

overlapTest() {
  // buffer:  xxxxxxxxyyyyyyyyzzzzzzzz  // 3 * float32
  // a0:       1 2 3 4 5 6 7 8 9101112  // 12 bytes
  // a1:         a b c d e              //  5 bytes
  // a2:           p q r s t            //  5 bytes
  var buffer = new Float32List(3).buffer;
  var a0 = new Int8List.view(buffer);
  var a1 = new Int8List.view(buffer, 1, 5);
  var a2 = new Int8List.view(buffer, 2, 5);
  initialize(a0);
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]', '$a0');
  Expect.equals('[2, 3, 4, 5, 6]', '$a1');
  Expect.equals('[3, 4, 5, 6, 7]', '$a2');
  a1.setRange(0, 5, a2);
  Expect.equals('[1, 3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12]', '$a0');

  initialize(a0);
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]', '$a0');
  Expect.equals('[2, 3, 4, 5, 6]', '$a1');
  Expect.equals('[3, 4, 5, 6, 7]', '$a2');
  a2.setRange(0, 5, a1);
  Expect.equals('[1, 2, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12]', '$a0');
}

main() {
  overlapTest();
}
