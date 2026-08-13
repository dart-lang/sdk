// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Reduced from
// The Dart Project Fuzz Tester (1.91).
// Program generated as:
//   dart dartfuzz.dart --seed 1052527605 --no-fp --no-ffi --flat

bool var31 = bool.hasEnvironment('z');

@pragma('vm:never-inline')
num foo0() {
  print(var31);
  return -4294967296;
}

main() {
  print(((-67) ~/ (var31 ? -83 : foo0())));
}
