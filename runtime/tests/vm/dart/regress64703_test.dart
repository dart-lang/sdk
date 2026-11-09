// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/64703.
// Verifies that catch entry parameters in nested catch blocks do not reuse
// the same stack slots and clobber live values from outer catch blocks.

// VMOptions=--optimization-counter-threshold=100 --deterministic

import 'package:expect/expect.dart';

@pragma('vm:never-inline')
void mayThrow(bool doThrow) {
  if (doThrow) throw 'error';
}

@pragma('vm:never-inline')
String test() {
  String a = 'initial';
  int b = 1;
  try {
    mayThrow(false);
    a = 'outer_try';
    mayThrow(true);
  } catch (_) {
    try {
      mayThrow(false);
      b = 42;
      mayThrow(true);
    } catch (_) {
      Expect.equals(42, b);
    }
  }
  return a;
}

void main() {
  for (int i = 0; i < 200; i++) {
    Expect.equals('outer_try', test());
  }
}
