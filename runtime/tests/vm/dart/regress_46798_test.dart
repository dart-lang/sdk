// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/46798.
// Verifies that compiler can handle LoadIndexed from AllocateObject.

// VMOptions=--deterministic --optimization_counter_threshold=100

import 'package:expect/expect.dart';

bool foo(Object other) => other is String && other.codeUnitAt(0) == 5;

int x = 0;

void bar(bool cond) {
  if (cond || foo(MapEntry<int, int>(1, 1))) {
    ++x;
  }
}

void main() {
  for (int i = 0; i < 1000; ++i) foo('abc');
  for (int i = 0; i < 1000; ++i) bar(false);
  Expect.equals(0, x);
}
