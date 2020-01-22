// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';
import 'setRange_lib.dart';

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
  expandContractTest();
}
