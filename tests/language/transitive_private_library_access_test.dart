// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to check that we can resolve unqualified identifiers

// Import 'dart:typed_data' which internally imports 'dart:_internal'.
import 'dart:typed_data';

import 'package:expect/expect.dart';

main() {
  bool exceptionCaught = false;
  try {
    // Attempt to access something in 'dart:_internal'.
    return ClassID.GetID(4);
    Expect.fail("Should have thrown an exception");
  } catch (e) {
    exceptionCaught = true;
  }
  Expect.isTrue(exceptionCaught);
}
