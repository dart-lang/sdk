// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Reduced from

// The Dart Project Fuzz Tester (1.89).
// Program generated as:
//   dart dartfuzz.dart --seed 3586617624 --no-fp --no-ffi --flat

import 'dart:typed_data';

Int32x4List var14 = Int32x4List(5);
Map<bool, int> var58 = {false: -5, true: -16, false: 22};

bool foo3_Extension1() {
  try {
    print(var14[((Int32x4.wyxw as int) >> var58[true]!)]);
    return true;
  } catch (e) {
    return false;
  }
}

main() {
  var r;
  try {
    r = foo3_Extension1();
  } catch (e) {
    Expect.fail("Exception should have been caught sooner");
  }
  Expect.equals(false, r);
}
