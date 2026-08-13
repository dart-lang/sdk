// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The Dart Project Fuzz Tester (1.101).
// Program generated as:
//   dart dartfuzz.dart --seed 2618914219 --no-fp --no-ffi --flat
// @dart=2.14

import 'dart:typed_data';
import 'dart:io';

@pragma("vm:never-inline")
foo() {
  Int8List(28).fillRange(-19, 25, 9223372034707292160);
}

main() {
  try {
    foo();
  } catch (e, st) {
    print('foo throws');
  }

  sleep(Duration(seconds: 3)); // Let background compiler catch up.
}
