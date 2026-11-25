// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for JIT retry on branch offset overflow reusing
// ParsedFunction context slots across CompilerState instances.

// VMOptions=--deterministic --optimization_counter_threshold=10

import 'package:expect/expect.dart';

int sink = 0;

@pragma('vm:never-inline')
void sideEffect(int x) => sink += x;

@pragma('vm:prefer-inline')
void b0(int x) {
  sideEffect(x + 1);
  sideEffect(x + 2);
  sideEffect(x + 3);
  sideEffect(x + 4);
}

@pragma('vm:prefer-inline')
void b1(int x) {
  b0(x + 1);
  b0(x + 2);
  b0(x + 3);
  b0(x + 4);
}

@pragma('vm:prefer-inline')
void b2(int x) {
  b1(x + 1);
  b1(x + 2);
  b1(x + 3);
  b1(x + 4);
}

@pragma('vm:prefer-inline')
void b3(int x) {
  b2(x + 1);
  b2(x + 2);
  b2(x + 3);
  b2(x + 4);
}

Iterable<Object> gen(Object x, bool expand) sync* {
  Object read() => x;
  yield read();
  if (expand) {
    b3(sink);
    b3(sink + 1);
    b3(sink + 2);
  }
}

void main() {
  for (var i = 0; i < 5; i++) {
    Expect.listEquals(['ok'], gen('ok', true).toList());
  }
  for (var i = 0; i < 20; i++) {
    Expect.equals('ok', gen('ok', false).first);
  }
}
