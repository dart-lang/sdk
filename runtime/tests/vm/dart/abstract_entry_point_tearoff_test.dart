// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The Dart Project Fuzz Tester (1.101).
// Program generated as:
//   dart dartfuzz.dart --seed 3834582911 --no-fp --no-ffi --flat
// @dart=2.14

class X0 {
  @pragma("vm:entry-point")
  @pragma("vm:never-inline")
  call() {}
}

class X2 with X0 {
  call() {
    throw "null";
  }
}

main() {
  try {
    X2()();
  } catch (e, st) {
    print('X2() throws');
  }
}
