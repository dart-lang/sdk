// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/48196.
// Verifies that compiler doesn't crash on unreachable code with conflicting
// types in Unbox instruction.

// Reduced from
// The Dart Project Fuzz Tester (1.93).
// Program generated as:
//   dart dartfuzz.dart --seed 2879764895 --no-fp --no-ffi --flat

// VMOptions=--deterministic --intrinsify=false --use-slow-path

import 'dart:typed_data';

Uint8List var8 = Uint8List.fromList(Uint16List.fromList(new Int8List(31)));
String var82 = 'Ub#H-k';

foo2() {
  return Int32x4List(29).sublist(0, 1).sublist(-1, -59);
}

foo0_Extension0() {
  Uri.encodeComponent(var82);
}

MapEntry<String, bool> foo1_Extension0() {
  for (int loc2 in (Int8List.fromList(var8))) {}
  return foo1_Extension0();
}

main() {
  try {
    foo2();
  } catch (e, st) {}
  try {
    foo0_Extension0();
  } catch (e, st) {}
  try {
    foo1_Extension0();
  } catch (e, st) {}
}
