// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --optimization_counter_threshold=10

import "package:expect/expect.dart";

import 'dart:typed_data';

// Found by DartFuzzing: truncating shift
// https://github.com/dart-lang/sdk/issues/38147

int bar(int x, int y) {
  return (x << y) & 0xffff;
}

@pragma("vm:never-inline")
int foo() {
  return bar(-61, 12);
}

main() {
  for (int i = 0; i < 20; i++) {
    Expect.equals(12288, foo());
  }
}
