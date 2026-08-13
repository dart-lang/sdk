// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The Dart Project Fuzz Tester (1.101).
// Program generated as:
//   dart dartfuzz.dart --seed 361710682 --no-fp --no-ffi --flat
// @dart=2.14

import 'dart:typed_data';

int foo3_Extension2() {
  try {
    IndexError.withLength(37, 15);
  } catch (exception, stackTrace) {}
  return 23;
}

@pragma("vm:never-inline")
foo0_0() {
  for (int loc0 in Int16List(30)) {
    Int32List.fromList(<int>[42]).sublist(<int>[foo3_Extension2()][200]!, 19);
  }
}

main() {
  try {
    foo0_0();
  } on RangeError catch (e) {
    print(e);
  }
}
