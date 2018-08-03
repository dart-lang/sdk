// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';
import 'setRange_lib.dart';

clampingTest() {
  var a1 = new Int8List(8);
  var a2 = new Uint8ClampedList.view(a1.buffer);
  initialize(a1);
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', '$a1');
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', '$a2');
  a1[0] = -1;
  a2.setRange(0, 2, a1);
  Expect.equals('[0, 2, 3, 4, 5, 6, 7, 8]', '$a2');
}

main() {
  clampingTest();
}
