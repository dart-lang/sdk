// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic

import "package:expect/expect.dart";

import 'dart:typed_data';

// Found by "value-guided" DartFuzzing: incorrect clamping.
// https://github.com/dart-lang/sdk/issues/37868
@pragma("vm:never-inline")
foo(List<int> x) => Uint8ClampedList.fromList(x);

@pragma("vm:never-inline")
bar(List<int> x) => Uint8List.fromList(x);

@pragma("vm:never-inline")
baz(List<int> x) => Int8List.fromList(x);

main() {
  // Proper values.
  final List<int> x = [
    9223372036854775807,
    -9223372036854775808,
    9223372032559808513,
    -9223372032559808513,
    5000000000,
    -5000000000,
    2147483647,
    -2147483648,
    255,
    -255,
    11,
    -11,
    0,
    -1,
  ];
  Expect.listEquals(
      [255, 0, 255, 0, 255, 0, 255, 0, 255, 0, 11, 0, 0, 0], foo(x));
  Expect.listEquals(
      [255, 0, 1, 255, 0, 0, 255, 0, 255, 1, 11, 245, 0, 255], bar(x));
  Expect.listEquals([-1, 0, 1, -1, 0, 0, -1, 0, -1, 1, 11, -11, 0, -1], baz(x));

  // Hidden null.
  final List<int> a = [1, null, 2];
  int num_exceptions = 0;
  try {
    foo(a);
  } on NoSuchMethodError catch (e) {
    num_exceptions++;
  }
  try {
    bar(a);
  } on NoSuchMethodError catch (e) {
    num_exceptions++;
  }
  try {
    baz(a);
  } on NoSuchMethodError catch (e) {
    num_exceptions++;
  }
  Expect.equals(3, num_exceptions);
}
