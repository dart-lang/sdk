// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test correct load elimination for scalar lists.

// TODO: remove once bug 2264 fixed.
library int_array_load_elimination;

import "package:expect/expect.dart";
import 'dart:typed_data';

void testUint16() {
  Uint16List intArray = new Uint16List(1);
  intArray[0] = -1;
  var x = intArray[0];
  Expect.equals(65535, x);
}

main() {
  for (int i = 0; i < 2000; i++) {
    testUint16();
  }
}
