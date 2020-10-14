// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --optimization_counter_threshold=80

// Verifies that JIT compiler doesn't crash when typed data allocation is
// used in unreachable LoadField(Array.length) due to polymorphic inlining.
// Regression test for https://github.com/dart-lang/sdk/issues/43679.

import 'dart:typed_data';
import 'package:expect/expect.dart';

main() {
  List<List> lists = [];
  for (int i = 0; i < 100; ++i) {
    lists.add(Uint32List.fromList(List<int>.filled(0, 0)));
    lists.add(Uint32List.fromList(Uint8List(3)));
  }
  for (int i = 0; i < lists.length; i += 2) {
    Expect.equals(0, lists[i].length);
    Expect.equals(3, lists[i + 1].length);
  }
}
